import 'package:flutter/material.dart';
import 'models/kiosk_state.dart';
import 'theme/kiosk_theme.dart';
import 'widgets/kiosk_frame.dart';

import 'screens/s01_language_selection_screen.dart';
import 'screens/s02_microphone_ask_screen.dart';
import 'screens/s03_processing_screen.dart';
import 'screens/s04_answer_screen.dart';

void main() {
  runApp(const CooperativeSahayakApp());
}

class CooperativeSahayakApp extends StatefulWidget {
  const CooperativeSahayakApp({super.key});

  @override
  State<CooperativeSahayakApp> createState() => _CooperativeSahayakAppState();
}

class _CooperativeSahayakAppState extends State<CooperativeSahayakApp> {
  final KioskStateNotifier _stateNotifier = KioskStateNotifier();

  @override
  void initState() {
    super.initState();
    _stateNotifier.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _stateNotifier.removeListener(_onStateChange);
    _stateNotifier.dispose();
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  Widget _buildCurrentScreen() {
    switch (_stateNotifier.currentScreenIndex) {
      case 1:
        return LanguageSelectionScreen(state: _stateNotifier);
      case 2:
        return MicrophoneAskScreen(state: _stateNotifier);
      case 3:
        return ProcessingScreen(state: _stateNotifier);
      case 4:
      case 5:
        return AnswerScreen(state: _stateNotifier);
      default:
        return LanguageSelectionScreen(state: _stateNotifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cooperative Sahayak',
      debugShowCheckedModeBanner: false,
      theme: KioskTheme.theme,
      home: KioskFrame(
        state: _stateNotifier,
        child: _buildCurrentScreen(),
      ),
    );
  }
}
