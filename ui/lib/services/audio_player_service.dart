import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer;

  AudioPlayerService({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Plays audio from a URL (e.g. returned by FastAPI)
  Future<bool> playUrl(String url) async {
    try {
      await stop();
      debugPrint('Playing audio from URL: $url');
      await _audioPlayer.play(UrlSource(url));
      _isPlaying = true;
      return true;
    } catch (e) {
      debugPrint('Error playing audio URL: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// Plays audio from a local file path
  Future<bool> playFile(String filePath) async {
    try {
      await stop();
      if (!kIsWeb && !filePath.startsWith('http')) {
        final file = File(filePath);
        if (!await file.exists() || (await file.length()) == 0) {
          debugPrint('Audio file does not exist or is empty: $filePath');
          return false;
        }
      }

      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;
      return true;
    } catch (e) {
      debugPrint('Error playing audio file: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// Stops current audio playback.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignore stop errors when idle
    } finally {
      _isPlaying = false;
    }
  }

  /// Pauses audio playback.
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      // Ignore pause errors
    } finally {
      _isPlaying = false;
    }
  }

  /// Clean up player resources.
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
  }
}
