import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

class KioskFrame extends StatelessWidget {
  final KioskStateNotifier state;
  final Widget child;

  const KioskFrame({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(state.selectedLanguageCode);

    return Scaffold(
      backgroundColor: KioskColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            _buildHeader(context, loc),

            // Main Display Card Container (White card inside Soft Sage Mint background)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: KioskColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KioskColors.primaryForestGreen, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, KioskLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: KioskColors.primaryForestGreen,
      ),
      child: Row(
        children: [
          // Kiosk Title & Icon
          const Icon(Icons.account_balance, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          const Text(
            'Cooperative Sahayak',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Georgia',
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),

          // Active Language Badge (Tap to change language)
          InkWell(
            onTap: () => state.setScreen(1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    KioskLocalizations.languageNames[state.selectedLanguageCode] ?? 'English',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Restart Session Touch Button
          if (state.currentScreenIndex > 1)
            InkWell(
              onTap: () => state.resetSession(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KioskColors.accentTerracotta,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      loc.getText('reset'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
