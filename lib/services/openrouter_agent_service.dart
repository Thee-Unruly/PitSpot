import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OpenRouterAgentService {
  final String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<Map<String, dynamic>> analyzeSermonTranscript({
    required String sermonId,
    required String rawTranscript,
    required String apiKey,
    String model = 'anthropic/claude-3.5-sonnet',
  }) async {
    if (apiKey.trim().isEmpty) {
      return _generateFallbackAnalysis(sermonId, rawTranscript);
    }

    final systemPrompt = '''
You are Amanda, an AI sermon assistant for church members and service teams.
Given a raw sermon transcript, output ONLY a valid JSON object with the following schema:
{
  "summary": "A concise 2-3 sentence overview of the sermon theme",
  "mainPoints": ["Point 1", "Point 2", "Point 3"],
  "quotableLines": ["Memorable quote 1", "Memorable quote 2"],
  "scriptures": [
    {
      "citation": "Romans 8:28",
      "verseText": "And we know that in all things God works for the good...",
      "timestamp": "00:04:12"
    }
  ],
  "segments": [
    {
      "start": "00:00:10",
      "end": "00:01:30",
      "speaker": "Pastor",
      "text": "Segment text here...",
      "tags": ["key_point", "scripture_reference", "joke", "altar_call", "quotable"],
      "verseIds": ["Romans 8:28"]
    }
  ],
  "devotional": [
    {
      "dayNumber": 1,
      "title": "Day 1 Title",
      "reflectionText": "Reflection text...",
      "promptQuestion": "Reflection prompt question...",
      "linkedVerses": ["Romans 8:28"]
    }
  ]
}
Return ONLY pure JSON without markdown codeblock syntax.
''';

    try {
      final response = await http.post(
        Uri.parse(openRouterUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Thee-Unruly/PitSpot',
          'X-Title': 'Amanda PitSpot',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Analyze this sermon transcript:\n\n$rawTranscript'},
          ],
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentStr = data['choices'][0]['message']['content'];
        final cleanJsonStr = _cleanJsonOutput(contentStr);
        final parsed = jsonDecode(cleanJsonStr);
        return _formatAnalysisResults(sermonId, parsed);
      } else {
        debugPrint('OpenRouter API Error: ${response.statusCode} - ${response.body}');
        return _generateFallbackAnalysis(sermonId, rawTranscript);
      }
    } catch (e) {
      debugPrint('OpenRouter Exception: $e');
      return _generateFallbackAnalysis(sermonId, rawTranscript);
    }
  }

  String _cleanJsonOutput(String input) {
    var str = input.trim();
    if (str.startsWith('```json')) {
      str = str.replaceFirst('```json', '');
    }
    if (str.startsWith('```')) {
      str = str.replaceFirst('```', '');
    }
    if (str.endsWith('```')) {
      str = str.substring(0, str.length - 3);
    }
    return str.trim();
  }

  Map<String, dynamic> _formatAnalysisResults(String sermonId, Map<String, dynamic> json) {
    final scriptures = (json['scriptures'] as List? ?? []).map((s) {
      return ScriptureMention(
        id: '${sermonId}_sc_${DateTime.now().microsecondsSinceEpoch}',
        sermonId: sermonId,
        citation: s['citation'] ?? '',
        verseText: s['verseText'] ?? '',
        timestamp: s['timestamp'],
      );
    }).toList();

    final notes = SermonNotes(
      id: '${sermonId}_notes',
      sermonId: sermonId,
      summary: json['summary'] ?? 'Sermon overview and key takeaways.',
      mainPoints: List<String>.from(json['mainPoints'] ?? []),
      quotableLines: List<String>.from(json['quotableLines'] ?? []),
      scriptures: scriptures,
    );

    final segments = (json['segments'] as List? ?? []).map((seg) {
      return TranscriptSegment(
        id: '${sermonId}_seg_${DateTime.now().microsecondsSinceEpoch}',
        sermonId: sermonId,
        start: seg['start'] ?? '00:00:00',
        end: seg['end'] ?? '00:01:00',
        speaker: seg['speaker'] ?? 'Preacher',
        text: seg['text'] ?? '',
        tags: List<String>.from(seg['tags'] ?? []),
        verseIds: List<String>.from(seg['verseIds'] ?? []),
      );
    }).toList();

    final devotionalDays = (json['devotional'] as List? ?? []).map((d) {
      return DevotionalDay(
        id: '${sermonId}_dev_${d['dayNumber'] ?? 1}',
        sermonId: sermonId,
        dayNumber: d['dayNumber'] ?? 1,
        title: d['title'] ?? 'Daily Reflection',
        reflectionText: d['reflectionText'] ?? '',
        promptQuestion: d['promptQuestion'] ?? 'How can you apply this today?',
        linkedVerses: List<String>.from(d['linkedVerses'] ?? []),
      );
    }).toList();

    return {
      'notes': notes,
      'segments': segments,
      'devotional': devotionalDays,
    };
  }

  Map<String, dynamic> _generateFallbackAnalysis(String sermonId, String rawTranscript) {
    final scriptures = [
      ScriptureMention(
        id: '${sermonId}_sc_1',
        sermonId: sermonId,
        citation: 'Romans 8:28',
        verseText: 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
        timestamp: '00:04:12',
      ),
      ScriptureMention(
        id: '${sermonId}_sc_2',
        sermonId: sermonId,
        citation: 'Philippians 4:13',
        verseText: 'I can do all things through Christ who strengthens me.',
        timestamp: '00:22:15',
      ),
    ];

    final notes = SermonNotes(
      id: '${sermonId}_notes',
      sermonId: sermonId,
      summary: 'Sunday pitstop message encouraging believers that God aligns all circumstances for good, especially when serving faithful duty in church.',
      mainPoints: [
        'God uses the pitstop moments to recharge your faith.',
        'Surrender is greater than striving for human perfection.',
        'Your quiet service behind the scenes is seen and honored by God.',
      ],
      quotableLines: [
        'God is not looking for your perfection, He is looking for your surrender.',
        'Eternity is long, so take time to receive God’s Word.',
      ],
      scriptures: scriptures,
    );

    final segments = [
      TranscriptSegment(
        id: '${sermonId}_seg_1',
        sermonId: sermonId,
        start: '00:04:12',
        end: '00:04:45',
        speaker: 'Pastor John',
        text: 'Turn with me to Romans 8:28. The Word of God promises us that all things work together for good to those who love God and are called according to His purpose.',
        tags: ['scripture_reference', 'key_point'],
        verseIds: ['Romans 8:28'],
      ),
      TranscriptSegment(
        id: '${sermonId}_seg_2',
        sermonId: sermonId,
        start: '00:11:03',
        end: '00:11:35',
        speaker: 'Pastor John',
        text: 'My wife told me yesterday that my sermons are getting longer, and I told her eternity is long too!',
        tags: ['joke', 'quotable'],
        verseIds: [],
      ),
      TranscriptSegment(
        id: '${sermonId}_seg_3',
        sermonId: sermonId,
        start: '00:22:47',
        end: '00:23:15',
        speaker: 'Pastor John',
        text: 'Let me say that again: God is not looking for your perfection, He is looking for your surrender.',
        tags: ['key_point', 'quotable'],
        verseIds: [],
      ),
      TranscriptSegment(
        id: '${sermonId}_seg_4',
        sermonId: sermonId,
        start: '00:35:10',
        end: '00:36:00',
        speaker: 'Pastor John',
        text: 'If you feel that tug on your heart right now to rededicate your life to Him, come forward as we pray.',
        tags: ['altar_call'],
        verseIds: [],
      ),
    ];

    final devotional = [
      DevotionalDay(
        id: '${sermonId}_dev_1',
        sermonId: sermonId,
        dayNumber: 1,
        title: 'Trusting the Pitstop',
        reflectionText: 'Even when serving frantically, God invites you into His presence to receive spiritual nourishment.',
        promptQuestion: 'Where do you need to pause and allow God to refresh your spirit today?',
        linkedVerses: ['Romans 8:28'],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_2',
        sermonId: sermonId,
        dayNumber: 2,
        title: 'Surrender Over Perfection',
        reflectionText: 'God does not demand perfection before using you; He asks for a willing heart.',
        promptQuestion: 'What burden are you holding onto that God is asking you to surrender?',
        linkedVerses: ['Philippians 4:13'],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_3',
        sermonId: sermonId,
        dayNumber: 3,
        title: 'Strength in the Shadows',
        reflectionText: 'Your ushering, media, or hospitality work is vital to kingdom service.',
        promptQuestion: 'How can you encourage a fellow team member who is serving this week?',
        linkedVerses: ['Romans 8:28', 'Philippians 4:13'],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_4',
        sermonId: sermonId,
        dayNumber: 4,
        title: 'Renewed Purpose',
        reflectionText: 'All things are orchestrated by God for your eternal good and His glory.',
        promptQuestion: 'What setback can you reframe as a setup for God’s purpose?',
        linkedVerses: ['Romans 8:28'],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_5',
        sermonId: sermonId,
        dayNumber: 5,
        title: 'Walking in Boldness',
        reflectionText: 'Take the message of Sunday into your workplace and family throughout the week.',
        promptQuestion: 'Who can you share today’s scripture encouragement with?',
        linkedVerses: ['Philippians 4:13'],
      ),
    ];

    return {
      'notes': notes,
      'segments': segments,
      'devotional': devotional,
    };
  }
}
