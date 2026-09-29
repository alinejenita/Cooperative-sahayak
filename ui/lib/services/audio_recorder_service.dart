import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder;

  AudioRecorderService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String? _currentRecordingPath;
  String? get currentRecordingPath => _currentRecordingPath;

  String? _dedicatedAudioInputPath;
  /// Deterministic file path inside the app directory reserved for AI Model input
  String? get dedicatedAudioInputPath => _dedicatedAudioInputPath;

  /// Checks and requests microphone permission across supported platforms.
  Future<bool> requestMicrophonePermission() async {
    try {
      if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return await _audioRecorder.hasPermission();
      }

      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.microphone.request();
      if (result.isGranted) {
        return true;
      }

      return await _audioRecorder.hasPermission();
    } catch (e) {
      try {
        return await _audioRecorder.hasPermission();
      } catch (_) {
        return false;
      }
    }
  }

  /// Gets the dedicated audio input directory inside the application sandbox.
  Future<Directory> getAudioInputDirectory() async {
    String baseDir;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      baseDir = docsDir.path;
    } catch (e) {
      debugPrint('Path provider fallback for dedicated audio dir: $e');
      baseDir = Directory.systemTemp.path;
    }

    final audioInputDir = Directory('$baseDir/audio_input');
    if (!await audioInputDir.exists()) {
      await audioInputDir.create(recursive: true);
    }
    return audioInputDir;
  }

  /// Starts recording audio and saves directly to the dedicated app input path for model consumption.
  Future<String?> startRecording({String? customPath}) async {
    try {
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted.');
      }

      String targetPath;
      if (customPath != null && customPath.isNotEmpty) {
        targetPath = customPath;
      } else if (kIsWeb) {
        targetPath = 'latest_user_query.mp3';
      } else {
        final audioInputDir = await getAudioInputDirectory();
        targetPath = '${audioInputDir.path}/latest_user_query.mp3';
      }

      _dedicatedAudioInputPath = targetPath;
      _currentRecordingPath = targetPath;

      const recordConfig = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(recordConfig, path: targetPath);
      _isRecording = true;
      return targetPath;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      debugPrint('Error starting audio recording: $e');
      rethrow;
    }
  }

  /// Stops recording and ensures the dedicated MP3 input file is ready for AI model processing.
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording && !(await _audioRecorder.isRecording())) {
        return _currentRecordingPath;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      final finalPath = path ?? _currentRecordingPath ?? _dedicatedAudioInputPath;
      _currentRecordingPath = finalPath;

      if (finalPath != null && !kIsWeb && !finalPath.startsWith('http')) {
        final file = File(finalPath);
        if (!await file.exists()) {
          debugPrint('Warning: Dedicated audio input file not found on disk at $finalPath');
        } else {
          debugPrint('Dedicated AI model audio input saved successfully at: $finalPath');
        }
      }

      return finalPath;
    } catch (e) {
      _isRecording = false;
      debugPrint('Error stopping audio recording: $e');
      return _currentRecordingPath;
    }
  }

  /// Cancels recording and discards active recording state.
  Future<void> cancelRecording() async {
    try {
      if (_isRecording || await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    } finally {
      _isRecording = false;
      _currentRecordingPath = null;
    }
  }

  /// Clean up recorder resources.
  Future<void> dispose() async {
    await cancelRecording();
    await _audioRecorder.dispose();
  }
}
