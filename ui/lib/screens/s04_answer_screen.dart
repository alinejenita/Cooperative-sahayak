import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

class AnswerScreen extends StatelessWidget {
  final KioskStateNotifier state;

  const AnswerScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(state.selectedLanguageCode);

    final bool isError = state.errorMessage != null && state.errorMessage!.isNotEmpty;
    final String answerText = isError
        ? state.errorMessage!
        : (state.nativeAnswer ?? loc.getText('a_member_rights'));
    final String? transcriptionText = state.transcription;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio Transcription Display (if available)
          if (transcriptionText != null && transcriptionText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: KioskColors.lightMintTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KioskColors.primaryForestGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: KioskColors.primaryForestGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recorded Query Transcription:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: KioskColors.mutedCharcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"$transcriptionText"',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: KioskColors.darkCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Answer Display Card & Audio Controls
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isError ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.verified,
                          color: isError ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isError ? 'Error' : loc.getText('yourAnswer'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isError ? KioskColors.accentTerracotta : KioskColors.primaryForestGreen,
                          ),
                        ),
                        const Spacer(),

                        // Replay / Speaker Button
                        if (!isError && state.audioUrl != null)
                          ElevatedButton.icon(
                            onPressed: () => state.toggleSpeaking(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.isSpeaking
                                  ? KioskColors.accentTerracotta
                                  : KioskColors.primaryForestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: Icon(
                              state.isSpeaking ? Icons.stop : Icons.volume_up,
                              size: 20,
                            ),
                            label: Text(
                              state.isSpeaking ? loc.getText('stopAudio') : loc.getText('repeat'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 1.2),

                    // Native Answer Text
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          answerText,
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.6,
                            color: isError ? KioskColors.accentTerracotta : KioskColors.darkCharcoal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => state.setScreen(2), // Ask another question
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KioskColors.primaryForestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.mic, size: 24),
                  label: Text(
                    loc.getText('askAnother'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => state.resetSession(), // Reset / Exit to main menu
                style: OutlinedButton.styleFrom(
                  foregroundColor: KioskColors.mutedCharcoal,
                  side: const BorderSide(color: KioskColors.mutedCharcoal, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 24),
                label: Text(
                  loc.getText('reset'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
