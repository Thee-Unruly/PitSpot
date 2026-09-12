import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _timer;
  int _elapsedSeconds = 0;

  bool get isRecording => _isRecording;
  int get elapsedSeconds => _elapsedSeconds;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording(Function(int seconds) onTick) async {
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'sermon_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = '${dir.path}/$fileName';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
    _elapsedSeconds = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);
    });
  }

  Future<String?> stopRecording() async {
    _timer?.cancel();
    _isRecording = false;
    final path = await _audioRecorder.stop();
    return path ?? _currentRecordingPath;
  }
}
