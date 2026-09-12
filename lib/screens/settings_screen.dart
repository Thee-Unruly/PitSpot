import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

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
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
    'qwen/qwen3.6-27b',
    'groq/compound-mini',
    'anthropic/claude-3.5-sonnet',
    'openai/gpt-4o',
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
      const SnackBar(content: Text('Groq / AI credentials saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Velora AI Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: [
          // Groq Provider Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: AppTheme.primaryAmber, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'High-Speed Groq Engine Active',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Powers real-time sermon analysis, Ask Velora Q&A, and Whisper transcriptions.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Groq / OpenRouter API Key',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your Groq API credentials (gsk_...). Supports GPT-OSS-120B, Qwen & Whisper-large-v3.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'gsk_... or sk-or-...',
              prefixIcon: Icon(Icons.key, color: AppTheme.primaryAmber),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Inference Model',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedModel,
            dropdownColor: AppTheme.darkSurface,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.psychology, color: Color(0xFFC084FC)),
            ),
            items: _models.map((m) {
              return DropdownMenuItem(value: m, child: Text(m));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedModel = val);
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
