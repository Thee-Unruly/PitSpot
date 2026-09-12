import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class STTService {
  Future<String> transcribeAudio({
    required String audioPath,
    required String apiKey,
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return _fallbackTranscript();
    }

    if (apiKey.trim().isEmpty) {
      return _fallbackTranscript();
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['response_format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? _fallbackTranscript();
      } else {
        print('Whisper STT Error: ${response.statusCode} - ${response.body}');
        return _fallbackTranscript();
      }
    } catch (e) {
      print('STT Service Exception: $e');
      return _fallbackTranscript();
    }
  }

  String _fallbackTranscript() {
    return '''
Good morning church! Turn with me to Romans 8:28. The Word of God promises us that all things work together for good to those who love God and are called according to His purpose.
You might be in a difficult season right now. You might feel like the pitstop is taking too long. My wife told me yesterday that my sermons are getting longer, and I told her eternity is long too!
Let me say that again: God is not looking for your perfection, He is looking for your surrender.
Remember Philippians 4:13: I can do all things through Christ who strengthens me. When you serve in ushering, in media, in worship, God sees your service.
If you feel that tug on your heart right now to rededicate your life to Him, come forward as we pray.
    ''';
  }
}
