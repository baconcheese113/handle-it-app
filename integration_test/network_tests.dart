import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handle_it/main.dart' as app;
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils.dart';

void networkTests() {
  group('network_test', () {
    setUpAll(() async {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool(introTutPrefKey, true);
    });

    testWidgets('Creates/deletes network and adds members', (widgetTester) async {
      app.main();
      await login(widgetTester);

      const MethodChannel('plugins.flutter.io/google_maps_0').setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'map#waitForMap') {
          return null;
        }
        return null;
      });
      await Future.delayed(const Duration(seconds: 3));

      final networkFinder = find.byKey(const ValueKey('navIcon.network'));
      await pumpUntilFound(widgetTester, networkFinder);
      expect(networkFinder, findsOneWidget);
      await widgetTester.tap(networkFinder);
      await widgetTester.pumpAndSettle();

      final membersFinder = find.byKey(const ValueKey('tab.members'));
      await pumpUntilFound(widgetTester, membersFinder);
      expect(membersFinder, findsOneWidget);
      await widgetTester.tap(membersFinder);
      await widgetTester.pumpAndSettle();

      final createNetworkFinder = find.byKey(const ValueKey('button.createNetwork'));
      expect(createNetworkFinder, findsOneWidget);
      await widgetTester.tap(createNetworkFinder);
      await widgetTester.pumpAndSettle();

      final networkNameFinder = find.byKey(const ValueKey('input.networkName'));
      expect(networkNameFinder, findsOneWidget);
      await widgetTester.enterText(networkNameFinder, "Test Network");

      final createFinder = find.byKey(const ValueKey('button.create'));
      expect(createFinder, findsOneWidget);
      await widgetTester.tap(createFinder);
      await widgetTester.pumpAndSettle();

      final networksFinder = find.byKey(const ValueKey('list.networks'));
      expect(networksFinder, findsOneWidget);
      await widgetTester.drag(networksFinder, const Offset(0, 500));
      await widgetTester.pumpAndSettle();

      const newMemberEmail = 'frand@user.com';

      final newMemberInputFinder = find.byKey(const ValueKey('input.newMember'));
      expect(newMemberInputFinder, findsOneWidget);
      await widgetTester.enterText(newMemberInputFinder, newMemberEmail);
      await widgetTester.pumpAndSettle();

      final newMemberButtonFinder = find.byKey(const ValueKey('button.newMember'));
      expect(newMemberButtonFinder, findsOneWidget);
      await widgetTester.tap(newMemberButtonFinder);
      await widgetTester.pumpAndSettle();

      // TODO get cache updates working
      // final newMemberFinder = find.textContaining(newMemberEmail);
      // expect(newMemberFinder, findsOneWidget);

      final deleteNetworkFinder = find.byKey(const ValueKey('button.deleteNetwork'));
      expect(deleteNetworkFinder, findsOneWidget);
      await widgetTester.tap(deleteNetworkFinder);
      await widgetTester.pumpAndSettle();
    });
  });
}
