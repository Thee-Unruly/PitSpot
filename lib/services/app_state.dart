import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'audio_recording_service.dart';
import 'database_helper.dart';
import 'live_speech_service.dart';
import 'openrouter_agent_service.dart';
import 'stt_service.dart';

enum ServiceRecordingStatus { idle, recording, processing, complete }

class AppState extends ChangeNotifier {
  final AudioRecordingService _audioService = AudioRecordingService();
  final LiveSpeechService _liveSpeechService = LiveSpeechService();
  final STTService _sttService = STTService();
  final OpenRouterAgentService _agentService = OpenRouterAgentService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  ServiceRecordingStatus _recordingStatus = ServiceRecordingStatus.idle;
  int _recordingSeconds = 0;
  String _processingStep = '';
  String _liveTranscript = '';
  double _soundLevel = 0.0;

  static const String defaultGroqApiKey = '';
  static const String defaultGroqModel = 'openai/gpt-oss-120b';

  String _openRouterApiKey = defaultGroqApiKey;
  String _openRouterModel = defaultGroqModel;
  String _whisperApiKey = defaultGroqApiKey;

  final List<ScriptureMention> _liveDetectedScriptures = [];
  Sermon? _currentSermon;
  SermonNotes? _currentNotes;
  List<TranscriptSegment> _currentSegments = [];
  List<DevotionalDay> _currentDevotional = [];
  List<Sermon> _vaultSermons = [];

  // Deep-link Bible target
  String? _targetBibleReference;

  ServiceRecordingStatus get recordingStatus => _recordingStatus;
  int get recordingSeconds => _recordingSeconds;
  String get processingStep => _processingStep;
  String get liveTranscript => _liveTranscript;
  double get soundLevel => _soundLevel;
  String get openRouterApiKey => _openRouterApiKey;
  String get openRouterModel => _openRouterModel;
  String get whisperApiKey => _whisperApiKey;
  List<ScriptureMention> get liveDetectedScriptures => _liveDetectedScriptures;

  Sermon? get currentSermon => _currentSermon;
  SermonNotes? get currentNotes => _currentNotes;
  List<TranscriptSegment> get currentSegments => _currentSegments;
  List<DevotionalDay> get currentDevotional => _currentDevotional;
  List<Sermon> get vaultSermons => _vaultSermons;
  String? get targetBibleReference => _targetBibleReference;

  AppState() {
    _loadSettingsAndVault();
  }

  Future<void> _loadSettingsAndVault() async {
    final prefs = await SharedPreferences.getInstance();
    _openRouterApiKey = prefs.getString('openrouter_api_key') ?? defaultGroqApiKey;
    _openRouterModel = prefs.getString('openrouter_model') ?? defaultGroqModel;
    _whisperApiKey = prefs.getString('whisper_api_key') ?? defaultGroqApiKey;

    _vaultSermons = await _dbHelper.getSermons();
    notifyListeners();
  }

  Future<void> saveSettings({required String apiKey, required String model, String? whisperKey}) async {
    _openRouterApiKey = apiKey;
    _openRouterModel = model;
    if (whisperKey != null) _whisperApiKey = whisperKey;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_api_key', apiKey);
    await prefs.setString('openrouter_model', model);
    if (whisperKey != null) await prefs.setString('whisper_api_key', whisperKey);

    notifyListeners();
  }

  void setTargetBibleReference(String ref) {
    _targetBibleReference = ref;
    notifyListeners();
  }

  Future<void> startServiceMode() async {
    _liveDetectedScriptures.clear();
    _liveTranscript = '';
    _soundLevel = 0.0;
    _recordingStatus = ServiceRecordingStatus.recording;
    _recordingSeconds = 0;
    notifyListeners();

    // 1. Start live on-device speech-to-text with real-time word streaming & scripture matching
    await _liveSpeechService.startListening(
      onText: (text) {
        _liveTranscript = text;
        notifyListeners();
      },
      onSound: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      onScripture: (mention) {
        if (!_liveDetectedScriptures.any((m) => m.citation.toLowerCase() == mention.citation.toLowerCase())) {
          _liveDetectedScriptures.add(mention);
          notifyListeners();
        }
      },
    );

    // 2. Start audio file recording
    try {
      await _audioService.startRecording((seconds) {
        _recordingSeconds = seconds;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Audio recording start error: $e');
    }
  }

  Future<void> stopServiceModeAndProcess() async {
    final liveCapturedSpeech = await _liveSpeechService.stopListening();
    final audioPath = await _audioService.stopRecording();

    _recordingStatus = ServiceRecordingStatus.processing;
    _processingStep = 'Finalizing live captured speech...';
    notifyListeners();

    var transcriptText = liveCapturedSpeech.trim();
    if (transcriptText.isEmpty && _liveTranscript.trim().isNotEmpty) {
      transcriptText = _liveTranscript.trim();
    }

    // Optional cloud STT fallback if on-device text was empty
    if (transcriptText.isEmpty && _whisperApiKey.isNotEmpty && audioPath != null) {
      _processingStep = 'Transcribing audio via Whisper Speech-to-Text...';
      notifyListeners();
      transcriptText = await _sttService.transcribeAudio(
        audioPath: audioPath,
        apiKey: _whisperApiKey,
        useFallback: false,
      );
    }

    if (transcriptText.isEmpty) {
      transcriptText = 'Live church service message.';
    }

    final sermonId = 'sermon_${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = DateTime.now().toIso8601String().split('T').first;

    // AI Analysis & Scripture Extraction from actual spoken words
    _processingStep = 'Extracting key sermon points & generating devotional...';
    notifyListeners();

    final analysis = await _agentService.analyzeSermonTranscript(
      sermonId: sermonId,
      rawTranscript: transcriptText,
      apiKey: _openRouterApiKey,
      model: _openRouterModel,
    );

    _currentNotes = analysis['notes'] as SermonNotes;
    _currentSegments = analysis['segments'] as List<TranscriptSegment>;
    _currentDevotional = analysis['devotional'] as List<DevotionalDay>;

    final readySermon = Sermon(
      id: sermonId,
      title: _currentNotes?.summary.split('.').first ?? 'Sunday Service Message',
      date: dateStr,
      preacher: 'Preacher',
      audioPath: audioPath,
      status: 'ready',
      themeSummary: _currentNotes?.summary,
    );
    _currentSermon = readySermon;

    // Save to SQLite Vault
    await _dbHelper.insertSermon(readySermon);
    await _dbHelper.insertTranscriptSegments(_currentSegments);
    if (_currentNotes != null) {
      await _dbHelper.saveSermonNotes(_currentNotes!);
    }
    await _dbHelper.saveDevotionalDays(_currentDevotional);

    _vaultSermons = await _dbHelper.getSermons();

    _recordingStatus = ServiceRecordingStatus.complete;
    notifyListeners();
  }

  Future<void> loadSermonFromVault(String sermonId) async {
    _currentSermon = await _dbHelper.getSermon(sermonId);
    _currentNotes = await _dbHelper.getSermonNotes(sermonId);
    _currentSegments = await _dbHelper.getTranscriptSegments(sermonId);
    _currentDevotional = await _dbHelper.getDevotionalDays(sermonId);
    notifyListeners();
  }

  Future<void> savePrayerNote(String dayId, String note) async {
    await _dbHelper.updatePrayerResponse(dayId, note);
    if (_currentSermon != null) {
      _currentDevotional = await _dbHelper.getDevotionalDays(_currentSermon!.id);
      notifyListeners();
    }
  }

  Future<String> askSermonQuestion(String question) async {
    final transcript = _currentSegments.map((s) => '${s.speaker}: ${s.text}').join('\n');
    return await _agentService.askSermonQuestion(
      question: question,
      sermonTitle: _currentSermon?.title ?? 'Sunday Sermon',
      transcript: transcript,
      sermonSummary: _currentNotes?.summary ?? 'Sermon summary',
      apiKey: _openRouterApiKey,
      model: _openRouterModel,
    );
  }

  void resetToHome() {
    _recordingStatus = ServiceRecordingStatus.idle;
    _liveTranscript = '';
    _soundLevel = 0.0;
    notifyListeners();
  }
}
