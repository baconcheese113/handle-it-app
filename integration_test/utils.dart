import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  bool timerDone = false;
  final timer = Timer(timeout, () => throw TimeoutException("Pump until has timed out"));
  while (timerDone != true) {
    await tester.pump();

    final found = tester.any(finder);
    if (found) {
      timerDone = true;
    }
  }
  timer.cancel();
}

Future<void> login(WidgetTester widgetTester) async {
  final tokenFinder = find.text("Checking for token...");
  await pumpUntilFound(widgetTester, tokenFinder);
  expect(tokenFinder, findsOneWidget);

  final emailInputFinder = find.widgetWithText(TextFormField, "Enter your email");
  await pumpUntilFound(widgetTester, emailInputFinder);
  expect(emailInputFinder, findsOneWidget);
  await widgetTester.enterText(emailInputFinder, "steve@user.com");

  final passwordInputFinder = find.widgetWithText(TextFormField, "Enter your password");
  expect(passwordInputFinder, findsOneWidget);
  await widgetTester.enterText(passwordInputFinder, "password");

  final loginFinder = find.byKey(const ValueKey('button.login'));
  expect(loginFinder, findsOneWidget);
  await widgetTester.tap(loginFinder);
  await widgetTester.pumpAndSettle();

  final fabFinder = find.byKey(const ValueKey('fab'));
  expect(fabFinder, findsOneWidget);
}
