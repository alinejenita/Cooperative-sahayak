import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvani/main.dart';

void main() {
  testWidgets('SarVani kiosk renders language selection and touches to proceed with localized UI', (WidgetTester tester) async {
    // Set surface size for HD Touchscreen kiosk view
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SarVaniApp());
    await tester.pumpAndSettle();

    // App name MUST always be in English: SarVani
    expect(find.textContaining('SarVani'), findsWidgets);
    expect(find.textContaining('தமிழ்'), findsWidgets);
    expect(find.textContaining('ಕನ್ನಡ'), findsWidgets);

    // Tap Tamil language button to proceed to Microphone / Ask screen
    await tester.tap(find.textContaining('தமிழ்').last);
    await tester.pumpAndSettle();

    // All screen elements should translate into Tamil
    expect(find.textContaining('உங்கள் கேள்வியைக் கேளுங்கள்'), findsWidgets);
    expect(find.textContaining('பேசத் தொடங்குங்கள்'), findsWidgets);
  });
}
