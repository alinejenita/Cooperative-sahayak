import 'package:flutter/material.dart';
import '../models/kiosk_state.dart';
import '../theme/kiosk_theme.dart';
import '../localization/kiosk_localizations.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final KioskStateNotifier state;

  const LanguageSelectionScreen({
    super.key,
    required this.state,
  });

  static const List<Map<String, String>> languages = [
    {'code': 'ta', 'native': 'தமிழ்', 'english': 'Tamil'},
    {'code': 'en', 'native': 'English', 'english': 'English'},
    {'code': 'hi', 'native': 'हिन्दी', 'english': 'Hindi'},
    {'code': 'te', 'native': 'తెలుగు', 'english': 'Telugu'},
    {'code': 'ml', 'native': 'മലയാളം', 'english': 'Malayalam'},
    {'code': 'kn', 'native': 'ಕನ್ನಡ', 'english': 'Kannada'},
  ];

  @override
  Widget build(BuildContext context) {
    final loc = KioskLocalizations(state.selectedLanguageCode);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title & Instruction Header
          Text(
            loc.getText('chooseLanguage'),
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Touch your language to begin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: KioskColors.mutedCharcoal,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Responsive Language Cards Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useThreeColumns = constraints.maxWidth > 650;
                final crossAxisCount = useThreeColumns ? 3 : 2;
                final aspectRatio = useThreeColumns ? 2.4 : 2.2;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = state.selectedLanguageCode == lang['code'];

                    return Material(
                      color: isSelected ? KioskColors.lightMintTint : KioskColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          state.setLanguage(lang['code']!);
                          state.setScreen(2); // Navigates directly to Microphone / Ask screen
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? KioskColors.primaryForestGreen
                                  : KioskColors.primaryForestGreen.withValues(alpha: 0.3),
                              width: isSelected ? 3.0 : 1.8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? KioskColors.primaryForestGreen
                                      : KioskColors.primaryForestGreen.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.translate,
                                  color: isSelected ? Colors.white : KioskColors.primaryForestGreen,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['native']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: KioskColors.primaryForestGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang['english']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: KioskColors.mutedCharcoal,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: KioskColors.primaryForestGreen,
                                  size: 26,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
