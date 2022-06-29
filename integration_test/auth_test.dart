import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handle_it/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('auth test', () {
    testWidgets("Should sign-in", (widgetTester) async {
      app.main();
      final tokenFinder = find.text("Checking for token...");
      await pumpUntilFound(widgetTester, tokenFinder);
      expect(tokenFinder, findsOneWidget);

      final emailInputFinder = find.widgetWithText(TextFormField, "Enter your email");
      await pumpUntilFound(widgetTester, emailInputFinder);
      expect(emailInputFinder, findsOneWidget);

      await widgetTester.enterText(emailInputFinder, "steve@user.com");
      await widgetTester.pumpAndSettle();

      final passwordInputFinder = find.widgetWithText(TextFormField, "Enter your password");
      expect(passwordInputFinder, findsOneWidget);
      await widgetTester.enterText(passwordInputFinder, "password");
      await widgetTester.pumpAndSettle();

      final loginFinder = find.byKey(const ValueKey('button.login'));
      expect(loginFinder, findsOneWidget);
      await widgetTester.tap(loginFinder);
      await widgetTester.pumpAndSettle();

      final skipFinder = find.byKey(const ValueKey('button.skip'));
      expect(skipFinder, findsOneWidget);
      await widgetTester.tap(skipFinder);
      await widgetTester.pumpAndSettle();

      final fabFinder = find.byKey(const ValueKey('fab'));
      expect(fabFinder, findsOneWidget);

      await Future.delayed(const Duration(seconds: 1));
    });
  });
}
