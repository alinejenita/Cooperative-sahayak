import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvani/models/kiosk_state.dart';
import 'package:sarvani/services/audio_recorder_service.dart';
import 'package:sarvani/services/audio_player_service.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class MockAudioRecorder implements AudioRecorder {
  bool hasPerm = true;
  bool isRec = false;
  String? startPath;
  String? stoppedPath;

  @override
  Future<bool> hasPermission({bool request = true}) async => hasPerm;

  @override
  Future<bool> isRecording() async => isRec;

  @override
  Future<bool> isPaused() async => false;

  @override
  Future<bool> isEncoderSupported(AudioEncoder encoder) async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    startPath = path;
    isRec = true;
  }

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    return const Stream.empty();
  }

  @override
  Future<String?> stop() async {
    isRec = false;
    stoppedPath = startPath ?? 'latest_user_query.mp3';
    return stoppedPath;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async {
    isRec = false;
  }

  @override
  Future<void> dispose() async {}

  @override
  Stream<Amplitude> onAmplitudeChanged(Duration interval) => const Stream.empty();

  @override
  Stream<RecordState> onStateChanged() => const Stream.empty();

  @override
  Future<Amplitude> getAmplitude() async => Amplitude(current: 0, max: 0);

  @override
  Future<List<InputDevice>> listInputDevices() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAudioPlayer implements AudioPlayer {
  bool playing = false;

  @override
  Future<void> stop() async {
    playing = false;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #play) {
      playing = true;
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioRecorderService & KioskStateNotifier Tests', () {
    late MockAudioRecorder mockRecorder;
    late MockAudioPlayer mockPlayer;
    late AudioRecorderService recorderService;
    late AudioPlayerService playerService;
    late KioskStateNotifier kioskState;

    setUp(() {
      mockRecorder = MockAudioRecorder();
      mockPlayer = MockAudioPlayer();
      recorderService = AudioRecorderService(audioRecorder: mockRecorder);
      playerService = AudioPlayerService(audioPlayer: mockPlayer);
      kioskState = KioskStateNotifier(recorderService: recorderService, playerService: playerService);
    });

    test('Microphone permission check returns expected status', () async {
      mockRecorder.hasPerm = true;
      final granted = await kioskState.checkAndRequestMicPermission();
      expect(granted, isTrue);
      expect(kioskState.hasMicPermission, isTrue);
      expect(kioskState.permissionError, isNull);
    });

    test('Microphone permission denied sets error message in state', () async {
      mockRecorder.hasPerm = false;
      final granted = await kioskState.checkAndRequestMicPermission();
      expect(granted, isFalse);
      expect(kioskState.hasMicPermission, isFalse);
      expect(kioskState.permissionError, contains('Microphone permission was denied'));
    });

    test('Start voice recording saves to recorded audio path', () async {
      mockRecorder.hasPerm = true;
      final success = await kioskState.startVoiceRecording();
      expect(success, isTrue);
      expect(kioskState.isRecording, isTrue);
      expect(kioskState.recordedMp3Path, endsWith('latest_user_query.mp3'));
      expect(mockRecorder.isRec, isTrue);
    });

    test('Stop voice recording finalizes recorded audio file path', () async {
      mockRecorder.hasPerm = true;
      await kioskState.startVoiceRecording();
      final mp3Path = await kioskState.stopVoiceRecording();

      expect(mp3Path, endsWith('latest_user_query.mp3'));
      expect(kioskState.isRecording, isFalse);
      expect(kioskState.recordedMp3Path, equals(mp3Path));
    });

    test('Cancel voice recording resets recording state', () async {
      mockRecorder.hasPerm = true;
      await kioskState.startVoiceRecording();
      await kioskState.cancelVoiceRecording();

      expect(kioskState.isRecording, isFalse);
      expect(kioskState.recordingDurationSeconds, equals(0));
    });

    test('Play answer audio handles idle state smoothly', () async {
      await kioskState.playAnswerAudio();
      expect(kioskState.isSpeaking, isFalse);
    });
  });
}
