import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'bible_service.dart';
import 'scripture_detector_service.dart';
import '../models/models.dart';

/// Real-time on-device speech-to-text service with live scripture citation detection.
class LiveSpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScriptureDetectorService _detector = ScriptureDetectorService();
  final BibleService _bibleService = BibleService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _finalizedText = '';
  String _currentStreamedWords = '';
  final Set<String> _detectedCitations = {};

  Function(String fullText)? onLiveTextUpdated;
  Function(double soundLevel)? onSoundLevelUpdated;
  Function(ScriptureMention mention)? onScriptureDetected;

  bool get isListening => _isListening;
  String get currentTranscript =>
      _finalizedText.isEmpty ? _currentStreamedWords : '$_finalizedText $_currentStreamedWords'.trim();

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' && _isListening) {
            _restartListening();
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('STT Init Exception: $e');
      return false;
    }
  }

  Future<void> startListening({
    Function(String fullText)? onText,
    Function(double level)? onSound,
    Function(ScriptureMention mention)? onScripture,
  }) async {
    onLiveTextUpdated = onText;
    onSoundLevelUpdated = onSound;
    onScriptureDetected = onScripture;

    _finalizedText = '';
    _currentStreamedWords = '';
    _detectedCitations.clear();
    _isListening = true;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        debugPrint('LiveSpeechService: device speech recognition not available');
        return;
      }
    }

    _listen();
  }

  void _listen() {
    if (!_isListening) return;

    try {
      _speech.listen(
        onResult: (result) {
          _currentStreamedWords = result.recognizedWords;
          final fullText = _finalizedText.isEmpty
              ? _currentStreamedWords
              : '$_finalizedText $_currentStreamedWords'.trim();

          onLiveTextUpdated?.call(fullText);

          // Run real-time scripture detector on the incoming words
          _scanForScriptures(fullText);

          if (result.finalResult) {
            _finalizedText = fullText;
            _currentStreamedWords = '';
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          onDevice: false,
          listenFor: const Duration(hours: 3),
          pauseFor: const Duration(seconds: 4),
        ),
        onSoundLevelChange: (level) {
          // Normalize sound level 0.0 -> 1.0
          final normalized = ((level + 20) / 35).clamp(0.0, 1.0);
          onSoundLevelUpdated?.call(normalized);
        },
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
    }
  }

  void _restartListening() {
    if (!_isListening) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isListening && !_speech.isListening) {
        _listen();
      }
    });
  }

  Future<void> _scanForScriptures(String text) async {
    final detailed = _detector.detectDetailedReferences(text);
    for (final det in detailed) {
      final key = det.citation.toLowerCase();
      if (_detectedCitations.contains(key)) continue;
      _detectedCitations.add(key);

      // Fetch actual verse text from bible.csv
      final verse = await _bibleService.fetchVerseText(det.citation);
      final mention = ScriptureMention(
        id: 'sc_${DateTime.now().millisecondsSinceEpoch}_${_detectedCitations.length}',
        sermonId: 'current',
        citation: det.citation,
        verseText: verse.text,
        timestamp: _getCurrentTimestamp(),
        type: det.type,
      );

      onScriptureDetected?.call(mention);
    }
  }

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<String> stopListening() async {
    _isListening = false;
    try {
      await _speech.stop();
    } catch (_) {}

    final fullText = _finalizedText.isEmpty
        ? _currentStreamedWords
        : '$_finalizedText $_currentStreamedWords'.trim();
    return fullText;
  }
}
