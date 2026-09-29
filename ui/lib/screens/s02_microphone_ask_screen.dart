import 'dart:async';
import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

class MicrophoneAskScreen extends StatefulWidget {
  final KioskStateNotifier state;

  const MicrophoneAskScreen({
    super.key,
    required this.state,
  });

  @override
  State<MicrophoneAskScreen> createState() => _MicrophoneAskScreenState();
}

class _MicrophoneAskScreenState extends State<MicrophoneAskScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.state.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleMicToggle() async {
    if (widget.state.isRecording) {
      // Stop recording and move to processing screen
      _recordingTimer?.cancel();
      _pulseController.stop();
      await widget.state.stopVoiceRecording();
      widget.state.setScreen(3); // Move to Processing Screen
    } else {
      // Start recording audio
      final started = await widget.state.startVoiceRecording();
      if (started) {
        _pulseController.repeat(reverse: true);
        widget.state.updateRecordingDuration(0);
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && widget.state.isRecording) {
            widget.state.updateRecordingDuration(timer.tick);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(widget.state.selectedLanguageCode);
    final isRec = widget.state.isRecording;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Main Screen Header
          Text(
            loc.getText('askQuestion'),
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.getText('speakNaturally'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: KioskColors.mutedCharcoal,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Microphone Button & Wave Animation Area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _handleMicToggle,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseVal = isRec ? _pulseController.value * 20 : 0.0;
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRec ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                            boxShadow: [
                              BoxShadow(
                                color: (isRec ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen)
                                    .withValues(alpha: 0.35),
                                blurRadius: 26 + pulseVal,
                                spreadRadius: 6 + pulseVal / 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRec ? Icons.stop_rounded : Icons.mic_rounded,
                                size: 96,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isRec ? loc.getText('stop') : loc.getText('tapToSpeak'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mic Status Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isRec ? KioskColors.warningBg : KioskColors.lightMintTint,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isRec ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRec ? Icons.fiber_manual_record : Icons.touch_app,
                          color: isRec ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isRec
                              ? '${loc.getText('listening')} (${widget.state.recordingDurationSeconds}s)'
                              : loc.getText('touchMicOrSpeak'),
                          style: TextStyle(
                            color: isRec ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
