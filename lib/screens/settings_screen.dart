import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _whisperKeyController;
  late String _selectedModel;

  final List<String> _models = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-haiku',
    'openai/gpt-4o',
    'google/gemini-2.0-flash-001',
    'meta-llama/llama-3.3-70b-instruct',
  ];

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _apiKeyController = TextEditingController(text: state.openRouterApiKey);
    _whisperKeyController = TextEditingController(text: state.whisperApiKey);
    _selectedModel = _models.contains(state.openRouterModel) ? state.openRouterModel : _models.first;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _whisperKeyController.dispose();
    super.dispose();
  }

  void _save() {
    final state = Provider.of<AppState>(context, listen: false);
    state.saveSettings(
      apiKey: _apiKeyController.text.trim(),
      model: _selectedModel,
      whisperKey: _whisperKeyController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amanda Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'OpenRouter Integration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your OpenRouter API Key to enable live Claude 3.5 Sonnet sermon analysis, moment tagging, and devotional generation.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'OpenRouter API Key',
              hintText: 'sk-or-v1-...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              labelText: 'OpenRouter LLM Model',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.psychology, color: Colors.blueAccent),
            ),
            items: _models.map((m) {
              return DropdownMenuItem(value: m, child: Text(m));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedModel = val);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Whisper STT Integration (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter an OpenAI API Key for direct Whisper speech transcription (or leave empty to use OpenRouter API key).',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _whisperKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Whisper / OpenAI Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.mic, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save Credentials & Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
