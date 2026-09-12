import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Audio recording service with chunked capture for live transcription.
///
/// Records audio in configurable-length chunks (default 25 seconds). Each
/// completed chunk triggers the [onChunkReady] callback with the file path
/// and chunk start time, enabling real-time speech-to-text processing and
/// scripture detection during the recording session.
///
/// The brief gap between chunks (~50-100ms for encoder stop/start) is
/// imperceptible in speech content.
class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _timer;
  int _elapsedSeconds = 0;

  /// Duration in seconds for each audio chunk.
  static const int _chunkDurationSeconds = 25;

  /// Session directory containing all chunk files.
  String? _chunkDir;
  int _chunkCount = 0;
  bool _isRotating = false;
  final List<String> _completedChunkPaths = [];

  /// Callback invoked when a completed chunk is ready for processing.
  Function(String chunkPath, int chunkStartSeconds)? _onChunkReady;

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Paths of all completed audio chunk files in this session.
  List<String> get completedChunkPaths => List.unmodifiable(_completedChunkPaths);

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Begin a chunked recording session.
  ///
  /// [onTick] is called every second with the total elapsed time.
  /// [onChunkReady] is called when each chunk file is finalized, providing
  /// the file path and the chunk's start time in seconds from session start.
  Future<void> startRecording(
    Function(int seconds) onTick, {
    Function(String chunkPath, int chunkStartSeconds)? onChunkReady,
  }) async {
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted.');
    }

    _onChunkReady = onChunkReady;
    _completedChunkPaths.clear();
    _chunkCount = 0;
    _isRotating = false;
    _elapsedSeconds = 0;

    // Create a session-specific directory for chunk files.
    final dir = await getApplicationDocumentsDirectory();
    _chunkDir = '${dir.path}/sermon_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(_chunkDir!).create(recursive: true);

    await _startNextChunk();
    _isRecording = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);

      // Rotate to a new chunk at each interval boundary.
      if (_elapsedSeconds > 0 &&
          _elapsedSeconds % _chunkDurationSeconds == 0 &&
          _isRecording &&
          !_isRotating) {
        _rotateChunk();
      }
    });
  }

  /// Start recording a new chunk file.
  Future<void> _startNextChunk() async {
    _chunkCount++;
    _currentRecordingPath =
        '$_chunkDir/chunk_${_chunkCount.toString().padLeft(3, '0')}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );
  }

  /// Finalize the current chunk and immediately begin the next one.
  Future<void> _rotateChunk() async {
    if (_isRotating || !_isRecording) return;
    _isRotating = true;

    try {
      final chunkStartSeconds = (_chunkCount - 1) * _chunkDurationSeconds;

      final completedPath = await _audioRecorder.stop();
      if (completedPath != null && completedPath.isNotEmpty) {
        _completedChunkPaths.add(completedPath);
        _onChunkReady?.call(completedPath, chunkStartSeconds);
      }

      if (_isRecording) {
        await _startNextChunk();
      }
    } catch (e) {
      debugPrint('Chunk rotation error: $e');
      // Attempt recovery: start a new chunk even if the stop failed.
      if (_isRecording) {
        try {
          await _startNextChunk();
        } catch (_) {}
      }
    } finally {
      _isRotating = false;
    }
  }

  /// Stop recording and finalize the last chunk.
  ///
  /// Returns the session directory path containing all audio chunk files,
  /// or null if no directory was created.
  Future<String?> stopRecording() async {
    _timer?.cancel();
    _isRecording = false;

    // Wait for any in-progress rotation to complete.
    while (_isRotating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    try {
      final lastChunkStartSeconds = (_chunkCount - 1) * _chunkDurationSeconds;
      final lastPath = await _audioRecorder.stop();
      if (lastPath != null && lastPath.isNotEmpty) {
        _completedChunkPaths.add(lastPath);
        _onChunkReady?.call(lastPath, lastChunkStartSeconds);
      }
    } catch (e) {
      debugPrint('Error stopping final chunk: $e');
    }

    return _chunkDir;
  }
}
