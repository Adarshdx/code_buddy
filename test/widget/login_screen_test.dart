import 'package:code_buddy/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/hive_setup.dart';

void main() {
  late HiveTestEnv env;

  setUpAll(() async {
    env = await bootstrapHive();
    // Prevent google_fonts from hitting the network during widget tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() async {
    await shutdownHive(env);
  });

  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(home: child),
      );

  Future<void> mountLogin(WidgetTester tester) async {
    // Give the login card room to lay out all of its buttons.
    await tester.binding.setSurfaceSize(const Size(1024, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(const LoginScreen()));
    // Let flutter_animate's fade/slide entrance finish.
    await tester.pumpAndSettle();
  }

  testWidgets('renders title, demo banner, and disabled Google button in demo mode', (tester) async {
    await mountLogin(tester);

    expect(find.text('Code-Buddy'), findsOneWidget);
    expect(
      find.textContaining('Demo mode: Firebase is not configured.'),
      findsOneWidget,
    );

    // Email and password fields.
    expect(find.byType(TextField), findsNWidgets(2));

    // The Google button is disabled and labeled accordingly.
    final googleButton = find.widgetWithText(OutlinedButton, 'Google sign-in (needs Firebase)');
    expect(googleButton, findsOneWidget);
    final outlined = tester.widget<OutlinedButton>(googleButton);
    expect(outlined.onPressed, isNull, reason: 'Google button should be disabled in demo mode');

    // "Try as guest" appears in demo mode.
    expect(find.text('Try as guest'), findsOneWidget);
  });

  testWidgets('toggling between login/signup updates the primary CTA', (tester) async {
    await mountLogin(tester);

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);

    // Tap the "New here?" toggle.
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });
}
