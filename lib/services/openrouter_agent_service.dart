import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'bible_service.dart';
import 'scripture_detector_service.dart';

class OpenRouterAgentService {
  final String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final ScriptureDetectorService _detector = ScriptureDetectorService();
  final BibleService _bibleService = BibleService();

  bool _isGroqKey(String key) => key.trim().startsWith('gsk_');

  Future<Map<String, dynamic>> analyzeSermonTranscript({
    required String sermonId,
    required String rawTranscript,
    required String apiKey,
    String model = 'openai/gpt-oss-120b',
  }) async {
    final cleanTranscript = rawTranscript.trim();

    if (apiKey.trim().isEmpty || cleanTranscript.isEmpty) {
      return await _generateDynamicTranscriptAnalysis(sermonId, cleanTranscript);
    }

    final isGroq = _isGroqKey(apiKey);
    final endpoint = isGroq ? groqUrl : openRouterUrl;
    final targetModel = isGroq
        ? (model.startsWith('llama-') ? 'openai/gpt-oss-120b' : model)
        : model;

    final systemPrompt = '''
You are Velora, an insightful sermon assistant for church members and pastors.
Given a raw sermon transcript, output ONLY a valid JSON object with the following schema:
{
  "summary": "A concise 2-3 sentence overview of the sermon theme",
  "mainPoints": ["Point 1", "Point 2", "Point 3"],
  "quotableLines": ["Memorable quote 1", "Memorable quote 2"],
  "scriptures": [
    {
      "citation": "Romans 8:28",
      "verseText": "And we know that in all things God works for the good...",
      "timestamp": "00:04:12",
      "type": "reference"
    }
  ],
  "segments": [
    {
      "start": "00:00:10",
      "end": "00:01:30",
      "speaker": "Preacher",
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
Return ONLY pure JSON without markdown codeblock formatting.
''';

    try {
      final headers = <String, String>{
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
      };
      if (!isGroq) {
        headers['HTTP-Referer'] = 'https://velora.bible';
        headers['X-Title'] = 'Velora Bible Companion';
      }

      final body = <String, dynamic>{
        'model': targetModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': 'Analyze this sermon transcript:\n\n$cleanTranscript'},
        ],
        'temperature': 0.2,
      };

      if (isGroq) {
        body['response_format'] = {'type': 'json_object'};
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentStr = data['choices'][0]['message']['content'];
        final cleanJsonStr = _cleanJsonOutput(contentStr);
        final parsed = jsonDecode(cleanJsonStr);
        return _formatAnalysisResults(sermonId, parsed);
      } else {
        debugPrint('LLM API Error (${isGroq ? "Groq" : "OpenRouter"}): ${response.statusCode} - ${response.body}');
        return await _generateDynamicTranscriptAnalysis(sermonId, cleanTranscript);
      }
    } catch (e) {
      debugPrint('LLM Exception: $e');
      return await _generateDynamicTranscriptAnalysis(sermonId, cleanTranscript);
    }
  }

  /// Interactive sermon Q&A assistant for Ask Velora (Screenshot 2).
  Future<String> askSermonQuestion({
    required String question,
    required String sermonTitle,
    required String transcript,
    required String sermonSummary,
    required String apiKey,
    String model = 'openai/gpt-oss-120b',
  }) async {
    if (apiKey.trim().isEmpty) {
      return 'I would love to help you reflect on "$sermonTitle"! To enable live AI reflection, please save your Groq API key in Settings.';
    }

    final isGroq = _isGroqKey(apiKey);
    final endpoint = isGroq ? groqUrl : openRouterUrl;
    final targetModel = isGroq
        ? (model.startsWith('llama-') ? 'openai/gpt-oss-120b' : model)
        : model;

    final systemPrompt = '''
You are Velora, a deeply reflective and biblically grounded Christian AI companion. You are discussing the sermon titled "$sermonTitle".
The theme of the message: "$sermonSummary".
Answer the user's question with theological richness, warmth, practical Christian living application, and direct relevance to what was preached in the sermon transcript.
Keep answers structured, concise (2-4 brief paragraphs), and encouraging.
Transcript:
$transcript
''';

    try {
      final headers = <String, String>{
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
      };
      if (!isGroq) {
        headers['HTTP-Referer'] = 'https://velora.bible';
        headers['X-Title'] = 'Velora Bible Companion';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          'model': targetModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': question},
          ],
          'temperature': 0.5,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response received from Velora.';
      } else {
        debugPrint('Ask Velora API Error: ${response.statusCode} - ${response.body}');
        return 'Could not reach Velora AI. Please check your Groq API key and network connection.';
      }
    } catch (e) {
      debugPrint('Ask Velora Exception: $e');
      return 'Unable to process your question at this moment. Please check your connection and try again.';
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
        type: s['type'] ?? 'reference',
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

  /// Dynamically extracts key points, detects scriptures from bible.csv,
  /// creates real timeline segments, and constructs a devotional from the user's ACTUAL transcript.
  Future<Map<String, dynamic>> _generateDynamicTranscriptAnalysis(
    String sermonId,
    String rawTranscript,
  ) async {
    final text = rawTranscript.trim();

    final detectedList = _detector.detectDetailedReferences(text);
    final scriptures = <ScriptureMention>[];

    for (int i = 0; i < detectedList.length; i++) {
      final det = detectedList[i];
      final verseObj = await _bibleService.fetchVerseText(det.citation);
      scriptures.add(
        ScriptureMention(
          id: '${sermonId}_sc_${i + 1}',
          sermonId: sermonId,
          citation: det.citation,
          verseText: verseObj.text,
          timestamp: '00:${(i * 15).toString().padLeft(2, '0')}',
          type: det.type,
        ),
      );
    }

    final sentences = text
        .split(RegExp(r'(?<=[.?!])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    String summary;
    if (sentences.isEmpty) {
      summary = 'Live service recording session. Real-time audio and speech captured.';
    } else if (sentences.length <= 3) {
      summary = sentences.join(' ');
    } else {
      summary = sentences.take(3).join(' ');
    }

    final mainPoints = <String>[];
    if (sentences.isNotEmpty) {
      for (final s in sentences) {
        if (s.length > 20 && !mainPoints.contains(s)) {
          mainPoints.add(s);
          if (mainPoints.length >= 4) break;
        }
      }
    }
    if (mainPoints.isEmpty) {
      mainPoints.add(text.isNotEmpty ? text : 'Recorded live message segment.');
    }

    final quotableLines = <String>[];
    for (final s in sentences) {
      if (s.length > 15 && s.length < 120 && !quotableLines.contains(s)) {
        quotableLines.add(s);
        if (quotableLines.length >= 3) break;
      }
    }

    final segments = <TranscriptSegment>[];
    if (sentences.isEmpty) {
      segments.add(
        TranscriptSegment(
          id: '${sermonId}_seg_1',
          sermonId: sermonId,
          start: '00:00:00',
          end: '00:00:30',
          speaker: 'Speaker',
          text: text.isNotEmpty ? text : 'Live sermon message segment.',
          tags: ['key_point'],
          verseIds: scriptures.map((s) => s.citation).toList(),
        ),
      );
    } else {
      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        final startSec = i * 20;
        final endSec = (i + 1) * 20;
        final startStr = '00:${(startSec ~/ 60).toString().padLeft(2, '0')}:${(startSec % 60).toString().padLeft(2, '0')}';
        final endStr = '00:${(endSec ~/ 60).toString().padLeft(2, '0')}:${(endSec % 60).toString().padLeft(2, '0')}';

        final tags = <String>['key_point'];
        final detectedInSentence = _detector.detectReferences(sentence);
        if (detectedInSentence.isNotEmpty) {
          tags.add('scripture_reference');
        }
        if (sentence.length < 60) {
          tags.add('quotable');
        }

        segments.add(
          TranscriptSegment(
            id: '${sermonId}_seg_${i + 1}',
            sermonId: sermonId,
            start: startStr,
            end: endStr,
            speaker: 'Speaker',
            text: sentence,
            tags: tags,
            verseIds: detectedInSentence,
          ),
        );
      }
    }

    final linkedCitations = scriptures.map((s) => s.citation).toList();
    final firstCitation = linkedCitations.isNotEmpty ? linkedCitations.first : 'Scripture Study';

    final devotional = [
      DevotionalDay(
        id: '${sermonId}_dev_1',
        sermonId: sermonId,
        dayNumber: 1,
        title: 'Receiving the Word',
        reflectionText: 'Reflect on today\'s service message: "$summary"',
        promptQuestion: 'What specific thought from today\'s message spoke most directly to you?',
        linkedVerses: linkedCitations.isNotEmpty ? [firstCitation] : [],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_2',
        sermonId: sermonId,
        dayNumber: 2,
        title: 'Walking in Obedience',
        reflectionText: 'Take the truths spoken today and examine how your daily routine can align with God’s purpose.',
        promptQuestion: 'What practical step can you take today in response to what you heard?',
        linkedVerses: linkedCitations,
      ),
      DevotionalDay(
        id: '${sermonId}_dev_3',
        sermonId: sermonId,
        dayNumber: 3,
        title: 'Faith in Action',
        reflectionText: 'Live out the core takeaway: ${mainPoints.first}',
        promptQuestion: 'How can you share this encouragement with someone in your church or family?',
        linkedVerses: linkedCitations,
      ),
      DevotionalDay(
        id: '${sermonId}_dev_4',
        sermonId: sermonId,
        dayNumber: 4,
        title: 'Renewing Your Mind',
        reflectionText: 'Meditate on the scriptures and reflections shared during this sermon message.',
        promptQuestion: 'Where do you need God\'s strength to persist in faith this week?',
        linkedVerses: linkedCitations.isNotEmpty ? [linkedCitations.last] : [],
      ),
      DevotionalDay(
        id: '${sermonId}_dev_5',
        sermonId: sermonId,
        dayNumber: 5,
        title: 'Standing Firm in Fellowship',
        reflectionText: 'Rejoice in the fellowship and continuous spiritual nourishment provided by God’s Word.',
        promptQuestion: 'Who can you pray for today to be strengthened in their walk of faith?',
        linkedVerses: linkedCitations,
      ),
    ];

    final notes = SermonNotes(
      id: '${sermonId}_notes',
      sermonId: sermonId,
      summary: summary,
      mainPoints: mainPoints,
      quotableLines: quotableLines,
      scriptures: scriptures,
    );

    return {
      'notes': notes,
      'segments': segments,
      'devotional': devotional,
    };
  }
}
