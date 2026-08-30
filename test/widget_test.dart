import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta/screens/onboarding_screen.dart';
import 'package:ruta/theme/app_theme.dart';

// A minimal smoke test so CI has something real to run. Tests the
// OnboardingScreen directly (skipping main()'s dotenv.load) since this
// build doesn't read env values anywhere yet.
void main() {
  testWidgets('OnboardingScreen renders the welcome copy and CTAs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: const OnboardingScreen(),
      ),
    );

    expect(find.textContaining('Every ride,'), findsOneWidget);
    expect(find.text('Start your logbook'), findsOneWidget);
    expect(find.text('I already ride here'), findsOneWidget);
  });
}
