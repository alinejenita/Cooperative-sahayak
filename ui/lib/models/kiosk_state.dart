import 'package:flutter/material.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../services/api_service.dart';

class KioskStateNotifier extends ChangeNotifier {
  final AudioRecorderService _recorderService;
  final AudioPlayerService _playerService;
  final ApiService _apiService;

  KioskStateNotifier({
    AudioRecorderService? recorderService,
    AudioPlayerService? playerService,
    ApiService? apiService,
  })  : _recorderService = recorderService ?? AudioRecorderService(),
        _playerService = playerService ?? AudioPlayerService(),
        _apiService = apiService ?? ApiService();

  AudioRecorderService get recorderService => _recorderService;
  AudioPlayerService get playerService => _playerService;

  // Screen Navigation Index (1: Language, 2: Microphone, 3: Processing, 4: Answer, 5: Menu)
  int _currentScreenIndex = 1;
  int get currentScreenIndex => _currentScreenIndex;

  // Selected Language code ('ta', 'hi', 'te', 'kn', 'ml')
  String _selectedLanguageCode = 'ta';
  String get selectedLanguageCode => _selectedLanguageCode;

  // Audio Playback state
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // Audio Recording state
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _hasMicPermission = false;
  bool get hasMicPermission => _hasMicPermission;

  String? _permissionError;
  String? get permissionError => _permissionError;

  String? _recordedMp3Path;
  String? get recordedMp3Path => _recordedMp3Path;

  int _recordingDurationSeconds = 0;
  int get recordingDurationSeconds => _recordingDurationSeconds;

  // Focus index for physical keypad navigation
  int _focusedIndex = 0;
  int get focusedIndex => _focusedIndex;

  // Pipeline API State
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _nativeAnswer;
  String? get nativeAnswer => _nativeAnswer;

  String? _transcription;
  String? get transcription => _transcription;

  String? _audioUrl;
  String? get audioUrl => _audioUrl;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setScreen(int index) {
    _currentScreenIndex = index.clamp(1, 5);
    _focusedIndex = 0;
    notifyListeners();
  }

  void setLanguage(String code) {
    _selectedLanguageCode = code;
    notifyListeners();
  }

  void setFocusedIndex(int index, int maxItems) {
    if (maxItems > 0) {
      _focusedIndex = (index + maxItems) % maxItems;
      notifyListeners();
    }
  }

  void moveFocusNext(int maxItems) {
    if (maxItems > 0) {
      _focusedIndex = (_focusedIndex + 1) % maxItems;
      notifyListeners();
    }
  }

  void moveFocusPrev(int maxItems) {
    if (maxItems > 0) {
      _focusedIndex = (_focusedIndex - 1 + maxItems) % maxItems;
      notifyListeners();
    }
  }

  // Permission and Recording methods
  Future<bool> checkAndRequestMicPermission() async {
    _permissionError = null;
    final granted = await _recorderService.requestMicrophonePermission();
    _hasMicPermission = granted;
    if (!granted) {
      _permissionError = 'Microphone permission was denied. Please grant microphone access.';
    }
    notifyListeners();
    return granted;
  }

  Future<bool> startVoiceRecording() async {
    _permissionError = null;
    _recordingDurationSeconds = 0;
    try {
      final granted = await checkAndRequestMicPermission();
      if (!granted) return false;

      final savedPath = await _recorderService.startRecording();
      if (savedPath != null) {
        _recordedMp3Path = savedPath;
        _isRecording = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isRecording = false;
      _permissionError = 'Failed to start recording: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      final path = await _recorderService.stopRecording();
      _isRecording = false;
      if (path != null) {
        _recordedMp3Path = path;
      }
      notifyListeners();
      return _recordedMp3Path;
    } catch (e) {
      _isRecording = false;
      debugPrint('Error stopping recording: $e');
      notifyListeners();
      return _recordedMp3Path;
    }
  }

  Future<void> cancelVoiceRecording() async {
    await _recorderService.cancelRecording();
    _isRecording = false;
    _recordingDurationSeconds = 0;
    notifyListeners();
  }

  void updateRecordingDuration(int seconds) {
    _recordingDurationSeconds = seconds;
    notifyListeners();
  }

  /// Submits selected language + recorded audio file to FastAPI Notebook Inference Pipeline
  Future<void> submitVoiceQuery() async {
    if (_recordedMp3Path == null || _recordedMp3Path!.isEmpty) {
      _errorMessage = 'No recorded audio available to process.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    _nativeAnswer = null;
    _transcription = null;
    _audioUrl = null;
    notifyListeners();

    try {
      final response = await _apiService.processVoiceQuery(
        audioFilePath: _recordedMp3Path!,
        languageCode: _selectedLanguageCode,
      );

      _transcription = response.transcription;
      _nativeAnswer = response.answerNative;
      _audioUrl = response.audioUrl;
      _isProcessing = false;
      _currentScreenIndex = 4; // Navigate to Answer Screen
      notifyListeners();

      // Auto-play generated Piper audio response if URL is available
      if (_audioUrl != null && _audioUrl!.isNotEmpty) {
        playAnswerAudio();
      }
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _currentScreenIndex = 4; // Show error on answer screen
      notifyListeners();
    }
  }

  /// Play or Replay response audio
  Future<void> playAnswerAudio() async {
    if (_audioUrl != null && _audioUrl!.isNotEmpty) {
      _isSpeaking = true;
      notifyListeners();
      final success = await _playerService.playUrl(_audioUrl!);
      if (!success && _recordedMp3Path != null) {
        await _playerService.playFile(_recordedMp3Path!);
      }
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Toggle response audio playback (Play/Stop)
  Future<void> toggleSpeaking() async {
    if (_isSpeaking) {
      await _playerService.stop();
      _isSpeaking = false;
    } else {
      await playAnswerAudio();
    }
    notifyListeners();
  }

  void resetSession() {
    cancelVoiceRecording();
    _playerService.stop();
    _recordedMp3Path = null;
    _nativeAnswer = null;
    _transcription = null;
    _audioUrl = null;
    _errorMessage = null;
    _currentScreenIndex = 1;
    _focusedIndex = 0;
    _isSpeaking = false;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _playerService.dispose();
    super.dispose();
  }
}
