import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'audio_recording_service.dart';
import 'database_helper.dart';
import 'openrouter_agent_service.dart';
import 'stt_service.dart';
import 'bible_service.dart';
import 'live_transcription_service.dart';
import 'scripture_detector_service.dart';

enum ServiceRecordingStatus { idle, recording, processing, complete }

class AppState extends ChangeNotifier {
  final AudioRecordingService _audioService = AudioRecordingService();
  final STTService _sttService = STTService();
  final OpenRouterAgentService _agentService = OpenRouterAgentService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ScriptureDetectorService _scriptureDetector = ScriptureDetectorService();
  final BibleService _bibleService = BibleService();
  LiveTranscriptionService? _liveTranscriptionService;

  ServiceRecordingStatus _recordingStatus = ServiceRecordingStatus.idle;
  int _recordingSeconds = 0;
  String _processingStep = '';

  String _openRouterApiKey = '';
  String _openRouterModel = 'anthropic/claude-3.5-sonnet';
  String _whisperApiKey = '';

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
    _openRouterApiKey = prefs.getString('openrouter_api_key') ?? '';
    _openRouterModel = prefs.getString('openrouter_model') ?? 'anthropic/claude-3.5-sonnet';
    _whisperApiKey = prefs.getString('whisper_api_key') ?? '';

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
    _recordingStatus = ServiceRecordingStatus.recording;
    _recordingSeconds = 0;
    notifyListeners();

    // Set up live transcription for real-time scripture detection
    _liveTranscriptionService?.onScriptureDetected = null;
    final apiKey = _whisperApiKey.isNotEmpty ? _whisperApiKey : _openRouterApiKey;
    _liveTranscriptionService = LiveTranscriptionService(
      sttService: _sttService,
      detector: _scriptureDetector,
      bibleService: _bibleService,
    );
    _liveTranscriptionService!.configure(apiKey: apiKey);
    _liveTranscriptionService!.onScriptureDetected = (mention) {
      _liveDetectedScriptures.add(mention);
      notifyListeners();
    };

    try {
      await _audioService.startRecording(
        (seconds) {
          _recordingSeconds = seconds;
          notifyListeners();
        },
        onChunkReady: (chunkPath, chunkStartSeconds) {
          _liveTranscriptionService?.enqueueChunk(chunkPath, chunkStartSeconds);
        },
      );
    } catch (e) {
      debugPrint('Failed to start recording: $e');
    }
  }

  Future<void> stopServiceModeAndProcess() async {
    final audioPath = await _audioService.stopRecording();
    _recordingStatus = ServiceRecordingStatus.processing;
    _processingStep = 'Finalizing audio capture...';
    notifyListeners();

    final sermonId = 'sermon_${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final newSermon = Sermon(
      id: sermonId,
      title: 'Sunday Service Message',
      date: dateStr,
      preacher: 'Pastor John',
      audioPath: audioPath,
      status: 'processing',
      themeSummary: 'God’s Pitstop Strength & Purpose',
    );
    _currentSermon = newSermon;

    // Step 1: Assemble transcript from live chunk-by-chunk transcription
    _processingStep = 'Assembling transcript from live capture...';
    notifyListeners();

    String transcriptText = '';
    if (_liveTranscriptionService != null) {
      transcriptText = await _liveTranscriptionService!.finalize();
    }

    // Fall back to full-file Whisper transcription if live transcript is empty
    if (transcriptText.trim().isEmpty) {
      _processingStep = 'Transcribing service audio via Whisper Speech-to-Text...';
      notifyListeners();
      transcriptText = await _sttService.transcribeAudio(
        audioPath: audioPath ?? '',
        apiKey: _whisperApiKey.isNotEmpty ? _whisperApiKey : _openRouterApiKey,
      );
    }

    // Step 2: OpenRouter AI Agent Analysis
    _processingStep = 'Analyzing sermon timeline & detecting scripture mentions via OpenRouter...';
    notifyListeners();
    final analysis = await _agentService.analyzeSermonTranscript(
      sermonId: sermonId,
      rawTranscript: transcriptText,
      apiKey: _openRouterApiKey,
      model: _openRouterModel,
    );

    // Step 3: Save to SQLite
    _processingStep = 'Saving sermon archive & generating 7-Day Devotional...';
    notifyListeners();

    _currentNotes = analysis['notes'] as SermonNotes;
    _currentSegments = analysis['segments'] as List<TranscriptSegment>;
    _currentDevotional = analysis['devotional'] as List<DevotionalDay>;

    final readySermon = Sermon(
      id: sermonId,
      title: _currentNotes?.summary.split('.').first ?? 'Sunday Message',
      date: dateStr,
      preacher: 'Pastor John',
      audioPath: audioPath,
      status: 'ready',
      themeSummary: _currentNotes?.summary,
    );
    _currentSermon = readySermon;

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

  void resetToHome() {
    _recordingStatus = ServiceRecordingStatus.idle;
    _liveTranscriptionService?.onScriptureDetected = null;
    _liveTranscriptionService = null;
    notifyListeners();
  }
}
