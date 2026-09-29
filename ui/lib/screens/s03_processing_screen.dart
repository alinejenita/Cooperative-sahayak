import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

class ProcessingScreen extends StatefulWidget {
  final KioskStateNotifier state;

  const ProcessingScreen({
    super.key,
    required this.state,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger FastAPI notebook pipeline call when entering processing screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.state.submitVoiceQuery();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(widget.state.selectedLanguageCode);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated Processing Indicator
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6.0,
              valueColor: AlwaysStoppedAnimation<Color>(KioskColors.primaryForestGreen),
            ),
          ),
          const SizedBox(height: 36),

          // Processing Stage Message
          Text(
            loc.getText('understandingQuestion'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: KioskColors.primaryForestGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            loc.getText('findingInformation'),
            style: const TextStyle(
              fontSize: 16,
              color: KioskColors.mutedCharcoal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
