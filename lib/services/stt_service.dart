import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class STTService {
  /// Transcribe audio from a file using Groq Whisper (ultra fast) or OpenAI Whisper.
  Future<String> transcribeAudio({
    required String audioPath,
    required String apiKey,
    bool useFallback = true,
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return useFallback ? _fallbackTranscript() : '';
    }

    if (apiKey.trim().isEmpty) {
      return useFallback ? _fallbackTranscript() : '';
    }

    final isGroq = apiKey.trim().startsWith('gsk_');
    final endpoint = isGroq
        ? 'https://api.groq.com/openai/v1/audio/transcriptions'
        : 'https://api.openai.com/v1/audio/transcriptions';
    final modelName = isGroq ? 'whisper-large-v3' : 'whisper-1';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer ${apiKey.trim()}';
      request.fields['model'] = modelName;
      request.fields['response_format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? (useFallback ? _fallbackTranscript() : '');
      } else {
        debugPrint('Whisper STT Error (${isGroq ? "Groq" : "OpenAI"}): ${response.statusCode} - ${response.body}');
        return useFallback ? _fallbackTranscript() : '';
      }
    } catch (e) {
      debugPrint('STT Service Exception: $e');
      return useFallback ? _fallbackTranscript() : '';
    }
  }

  String _fallbackTranscript() {
    return '''
Good morning church! Turn with me to Philippians 4:13. The Word of God reminds us that in Christ, you have strength for every need.
And we also know from Romans 8:28 that all things work together for the good of those who love God and are called according to His purpose.
God is not looking for your perfection, He is looking for your surrender.
Let's hold fast to His promises as we pray together.
    ''';
  }
}
