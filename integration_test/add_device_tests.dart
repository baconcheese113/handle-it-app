import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handle_it/main.dart' as app;
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_ble_provider.dart';
import 'utils.dart';

void addDeviceTests() {
  group('add_device', () {
    setUpAll(() async {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool(introTutPrefKey, true);
    });

    testWidgets('Creates a hub, then adds sensor', (widgetTester) async {
      final mockBleProvider = FakeBleProvider();
      app.main(bleProvider: mockBleProvider);
      await login(widgetTester);

      // TODO remove
      await Future.delayed(const Duration(seconds: 3));

      final fabFinder = find.byKey(const ValueKey('fab'));
      await pumpUntilFound(widgetTester, fabFinder);
      expect(fabFinder, findsOneWidget);
      await tapAndWaitMs(widgetTester, fabFinder, 0);

      final startScanFinder = find.byKey(const ValueKey('button.startScan'));
      expect(startScanFinder, findsOneWidget);
    });
  });
}
