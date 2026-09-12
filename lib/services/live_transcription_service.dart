import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'bible_service.dart';
import 'scripture_detector_service.dart';
import 'stt_service.dart';

/// Orchestrates periodic live transcription and scripture detection during
/// an active recording session.
///
/// As audio chunks are completed by [AudioRecordingService], they are enqueued
/// here for transcription via [STTService] and scripture detection via
/// [ScriptureDetectorService]. Detected scriptures trigger [onScriptureDetected]
/// callbacks for real-time UI updates.
///
/// After recording stops, [finalize] processes any remaining chunks and returns
/// the full accumulated transcript for downstream AI analysis — eliminating
/// the need for a second full-file Whisper call.
class LiveTranscriptionService {
  final STTService _sttService;
  final ScriptureDetectorService _detector;
  final BibleService _bibleService;

  final List<String> _chunkTranscripts = [];
  final Set<String> _detectedCitationKeys = {};
  final List<_PendingChunk> _pendingChunks = [];
  bool _isProcessing = false;
  String _apiKey = '';

  /// Callback invoked each time a new, previously-unseen scripture reference
  /// is detected in a transcription chunk.
  Function(ScriptureMention mention)? onScriptureDetected;

  LiveTranscriptionService({
    required STTService sttService,
    required ScriptureDetectorService detector,
    required BibleService bibleService,
  })  : _sttService = sttService,
        _detector = detector,
        _bibleService = bibleService;

  /// The full transcript assembled by concatenating all processed chunks.
  String get accumulatedTranscript => _chunkTranscripts.join('\n');

  /// Whether any transcript text has been accumulated from processed chunks.
  bool get hasTranscript => _chunkTranscripts.isNotEmpty;

  /// Set the API key used for Whisper transcription.
  /// If empty, [enqueueChunk] is a no-op (no live detection without credentials).
  void configure({required String apiKey}) {
    _apiKey = apiKey;
  }

  /// Enqueue a completed audio chunk for background transcription & detection.
  ///
  /// [chunkPath] — absolute path to the finalized .m4a chunk file.
  /// [chunkStartSeconds] — elapsed recording time (seconds) when this chunk began.
  void enqueueChunk(String chunkPath, int chunkStartSeconds) {
    if (_apiKey.trim().isEmpty) return;
    _pendingChunks.add(_PendingChunk(chunkPath, chunkStartSeconds));
    _drainQueue();
  }

  // ─── Internal queue processing ───────────────────────────────────────────

  /// Sequentially process pending chunks. Re-entrant safe: if [_isProcessing]
  /// is already true, this returns immediately. The running invocation's
  /// while-loop will pick up any newly enqueued chunks.
  Future<void> _drainQueue() async {
    if (_isProcessing || _pendingChunks.isEmpty) return;
    _isProcessing = true;

    try {
      while (_pendingChunks.isNotEmpty) {
        final chunk = _pendingChunks.removeAt(0);
        await _processChunk(chunk);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Transcribe a single chunk and run scripture detection on the result.
  Future<void> _processChunk(_PendingChunk chunk) async {
    try {
      final transcript = await _sttService.transcribeAudio(
        audioPath: chunk.path,
        apiKey: _apiKey,
        useFallback: false, // Never use hardcoded fallback for live chunks
      );

      if (transcript.trim().isEmpty) return;

      _chunkTranscripts.add(transcript);

      // Detect Bible references in the transcribed text
      final refs = _detector.detectReferences(transcript);
      for (final ref in refs) {
        final key = ref.toLowerCase();
        if (_detectedCitationKeys.contains(key)) continue;
        _detectedCitationKeys.add(key);

        // Look up verse text from local Bible database
        final verse = await _bibleService.fetchVerseText(ref);
        final timestamp = _formatTimestamp(chunk.startSeconds);

        final mention = ScriptureMention(
          id: 'live_${DateTime.now().millisecondsSinceEpoch}_${_detectedCitationKeys.length}',
          sermonId: 'current',
          citation: ref,
          verseText: verse.text,
          timestamp: timestamp,
        );

        onScriptureDetected?.call(mention);
      }
    } catch (e) {
      debugPrint('Live chunk transcription error: $e');
    }
  }

  // ─── Public lifecycle ────────────────────────────────────────────────────

  /// Process any remaining queued chunks and return the full accumulated
  /// transcript. Call this after recording stops, before passing the
  /// transcript to OpenRouter for analysis.
  Future<String> finalize() async {
    // Wait for any in-flight chunk processing to complete.
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Process any chunks enqueued after the last drain cycle completed.
    if (_pendingChunks.isNotEmpty) {
      _isProcessing = true;
      try {
        while (_pendingChunks.isNotEmpty) {
          final chunk = _pendingChunks.removeAt(0);
          await _processChunk(chunk);
        }
      } finally {
        _isProcessing = false;
      }
    }

    return accumulatedTranscript;
  }

  /// Clear all accumulated state. Called automatically when a new recording
  /// session starts (a fresh instance is created per session).
  void reset() {
    _chunkTranscripts.clear();
    _detectedCitationKeys.clear();
    _pendingChunks.clear();
    _isProcessing = false;
    onScriptureDetected = null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _formatTimestamp(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// Internal model for a chunk awaiting transcription.
class _PendingChunk {
  final String path;
  final int startSeconds;
  const _PendingChunk(this.path, this.startSeconds);
}
