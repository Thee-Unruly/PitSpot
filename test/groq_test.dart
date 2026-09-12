import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Groq API Model Connectivity Test', () async {
    final apiKey = Platform.environment['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      // Skipped when running in CI without key
      return;
    }

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'openai/gpt-oss-120b',
        'messages': [
          {'role': 'user', 'content': 'Praise the Lord in one short sentence.'},
        ],
        'temperature': 0.3,
      }),
    );

    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    expect(content, isNotEmpty);
  });
}
