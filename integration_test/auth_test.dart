import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handle_it/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'utils.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  await storage.deleteAll();

  group('auth test', () {
    testWidgets("Should register", (widgetTester) async {
      app.main();
      final tokenFinder = find.text("Checking for token...");
      await pumpUntilFound(widgetTester, tokenFinder);
      expect(tokenFinder, findsOneWidget);

      final registerButton = find.byKey(const ValueKey('button.switchToRegister'));
      await pumpUntilFound(widgetTester, registerButton);
      expect(registerButton, findsOneWidget);
      await widgetTester.tap(registerButton);

      final firstNameInputFinder = find.widgetWithText(TextFormField, "Enter your first name (optional)");
      await pumpUntilFound(widgetTester, firstNameInputFinder);
      expect(firstNameInputFinder, findsOneWidget);
      await widgetTester.enterText(firstNameInputFinder, "Steve");

      final lastNameInputFinder = find.widgetWithText(TextFormField, "Enter your last name (optional)");
      expect(lastNameInputFinder, findsOneWidget);
      await widgetTester.enterText(lastNameInputFinder, "Buscemi");

      final secSinceEpoch = DateTime.now().millisecondsSinceEpoch / 1000;
      final email = "steve+$secSinceEpoch@user.com";

      final emailInputFinder = find.widgetWithText(TextFormField, "Enter your email");
      expect(emailInputFinder, findsOneWidget);
      await widgetTester.enterText(emailInputFinder, email);

      final passwordInputFinder = find.widgetWithText(TextFormField, "Enter your password");
      expect(passwordInputFinder, findsOneWidget);
      await widgetTester.enterText(passwordInputFinder, "password");

      final loginFinder = find.byKey(const ValueKey('button.register'));
      expect(loginFinder, findsOneWidget);
      await widgetTester.tap(loginFinder);
      await widgetTester.pumpAndSettle();

      final skipFinder = find.byKey(const ValueKey('button.skip'));
      await pumpUntilFound(widgetTester, skipFinder);
      expect(skipFinder, findsOneWidget);
      await widgetTester.tap(skipFinder);
      await widgetTester.pumpAndSettle();

      final profileFinder = find.byKey(const ValueKey('navIcon.profile'));
      expect(profileFinder, findsOneWidget);
      await widgetTester.tap(profileFinder);

      final logoutFinder = find.byKey(const ValueKey('button.logout'));
      await pumpUntilFound(widgetTester, logoutFinder);
      expect(logoutFinder, findsOneWidget);
      await widgetTester.tap(logoutFinder);
    });

    testWidgets("Should sign-in", (widgetTester) async {
      app.main();
      await login(widgetTester);
    });
  });
}
