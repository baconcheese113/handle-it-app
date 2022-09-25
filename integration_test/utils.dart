import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  bool timerDone = false;
  final timer = Timer(timeout, () => timerDone = true);
  while (timerDone != true) {
    await tester.pumpAndSettle();

    final found = tester.any(finder);
    if (found) {
      timerDone = true;
    }
  }
  timer.cancel();
}

const TEST_USER_EMAIL = "steve@user.com";

Future<void> login(WidgetTester widgetTester) async {
  // Leads to flaky tests
  // final tokenFinder = find.text("Checking for token...");
  // await pumpUntilFound(widgetTester, tokenFinder);
  // expect(tokenFinder, findsOneWidget);

  final emailInputFinder = find.widgetWithText(TextFormField, "Enter your email");
  await pumpUntilFound(widgetTester, emailInputFinder);
  expect(emailInputFinder, findsOneWidget);
  await widgetTester.enterText(emailInputFinder, TEST_USER_EMAIL);

  final passwordInputFinder = find.widgetWithText(TextFormField, "Enter your password");
  expect(passwordInputFinder, findsOneWidget);
  await widgetTester.enterText(passwordInputFinder, "password");

  final loginFinder = find.byKey(const ValueKey('button.login'));
  expect(loginFinder, findsOneWidget);
  await tapAndWaitMs(widgetTester, loginFinder, 200);

  final loginErrorText = find.byKey(const ValueKey('text.loginError'));
  final error = loginErrorText.evaluate().singleOrNull?.widget as Text?;
  expect(error, isNull);

  final fabFinder = find.byKey(const ValueKey('fab'));
  await pumpUntilFound(widgetTester, fabFinder);
  expect(fabFinder, findsOneWidget);
}

// Useful for waiting for mock BLE delays
Future<void> tapAndWaitMs(
  WidgetTester widgetTester,
  Finder finder,
  int milliseconds,
) async {
  await widgetTester.pumpAndSettle();
  await widgetTester.tap(finder);
  await widgetTester.pumpAndSettle();
  if (milliseconds > 0) {
    await Future.delayed(Duration(milliseconds: milliseconds));
    await widgetTester.pumpAndSettle();
  }
}

GraphQLClient getClient({String? token}) {
  final HttpLink httpLink = HttpLink(dotenv.env['API_URL']!);
  final AuthLink authLink = AuthLink(getToken: () => token != null ? "Bearer $token" : null);
  final link = authLink.concat(httpLink);
  return GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
  );
}
