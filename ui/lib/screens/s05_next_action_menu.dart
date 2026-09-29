import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

enum ContextualViewType {
  none,
  documents,
  nextSteps,
  helpInfo,
}

class NextActionMenuWidget extends StatelessWidget {
  final KioskStateNotifier state;
  final ContextualViewType activeView;
  final ValueChanged<ContextualViewType> onViewChanged;

  const NextActionMenuWidget({
    super.key,
    required this.state,
    required this.activeView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(state.selectedLanguageCode);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        // 1. 🎤 Ask Another Question
        _buildActionButton(
          context,
          icon: Icons.mic,
          label: loc.getText('askAnother'),
          color: KioskColors.primaryForestGreen,
          isPrimary: true,
          onTap: () => state.setScreen(2),
        ),

        // 2. 🔊 Hear Again
        _buildActionButton(
          context,
          icon: state.isSpeaking ? Icons.volume_up : Icons.volume_down_outlined,
          label: state.isSpeaking ? loc.getText('stopAudio') : loc.getText('repeat'),
          color: state.isSpeaking ? KioskColors.accentTerracotta : KioskColors.secondaryTeal,
          onTap: () => state.toggleSpeaking(),
        ),

        // 3. 📄 Required Documents
        _buildActionButton(
          context,
          icon: Icons.description,
          label: loc.getText('showDocuments'),
          color: activeView == ContextualViewType.documents
              ? KioskColors.primaryForestGreen
              : KioskColors.darkCharcoal,
          isSelected: activeView == ContextualViewType.documents,
          onTap: () {
            onViewChanged(
              activeView == ContextualViewType.documents
                  ? ContextualViewType.none
                  : ContextualViewType.documents,
            );
          },
        ),

        // 4. ➡️ Next Steps
        _buildActionButton(
          context,
          icon: Icons.alt_route,
          label: loc.getText('actionNextStepLabel'),
          color: activeView == ContextualViewType.nextSteps
              ? KioskColors.primaryForestGreen
              : KioskColors.darkCharcoal,
          isSelected: activeView == ContextualViewType.nextSteps,
          onTap: () {
            onViewChanged(
              activeView == ContextualViewType.nextSteps
                  ? ContextualViewType.none
                  : ContextualViewType.nextSteps,
            );
          },
        ),

        // 5. 📞 Help / Complaint Info
        _buildActionButton(
          context,
          icon: Icons.headset_mic,
          label: loc.getText('getHumanHelp'),
          color: activeView == ContextualViewType.helpInfo
              ? KioskColors.primaryForestGreen
              : KioskColors.darkCharcoal,
          isSelected: activeView == ContextualViewType.helpInfo,
          onTap: () {
            onViewChanged(
              activeView == ContextualViewType.helpInfo
                  ? ContextualViewType.none
                  : ContextualViewType.helpInfo,
            );
          },
        ),

        // 6. 🚪 Exit
        _buildActionButton(
          context,
          icon: Icons.logout,
          label: loc.getText('endSession'),
          color: KioskColors.accentTerracotta,
          onTap: () => state.resetSession(),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? KioskColors.lightMintTint
          : (isPrimary ? color : Colors.white),
      borderRadius: BorderRadius.circular(12),
      elevation: isPrimary ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? KioskColors.primaryForestGreen : color.withValues(alpha: 0.5),
              width: isSelected ? 2.2 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? KioskColors.primaryForestGreen : (isPrimary ? Colors.white : color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? KioskColors.primaryForestGreen : (isPrimary ? Colors.white : color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
