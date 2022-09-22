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

      final fab = find.byKey(const ValueKey('fab'));
      await pumpUntilFound(widgetTester, fab);
      expect(fab, findsOneWidget);
      await tapAndWaitMs(widgetTester, fab, 0);

      final startScanButton = find.byKey(const ValueKey('button.startScan'));
      expect(startScanButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, startScanButton, 0);

      final setNameButton = find.byKey(const ValueKey('button.setName')).hitTestable();
      await pumpUntilFound(widgetTester, setNameButton);
      expect(setNameButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, setNameButton, 0);

      var cardMenuButton = find.byKey(const ValueKey('button.cardMenu'), skipOffstage: false).last;
      await pumpUntilFound(widgetTester, cardMenuButton);
      await widgetTester.ensureVisible(cardMenuButton);
      await tapAndWaitMs(widgetTester, cardMenuButton, 0);

      final addSensorMenuItem = find.byKey(const ValueKey('menuItem.addSensor'));
      await pumpUntilFound(widgetTester, addSensorMenuItem);
      await tapAndWaitMs(widgetTester, addSensorMenuItem, 0);

      final startSearchButton = find.byKey(const ValueKey('button.startSearch'));
      await pumpUntilFound(widgetTester, startSearchButton);
      await tapAndWaitMs(widgetTester, startSearchButton, 0);

      final saveButton = find.byKey(const ValueKey('button.save')).hitTestable();
      await pumpUntilFound(widgetTester, saveButton);
      await tapAndWaitMs(widgetTester, saveButton, 500);

      await pumpUntilFound(widgetTester, cardMenuButton);
      expect(cardMenuButton, findsOneWidget);
      await widgetTester.ensureVisible(cardMenuButton);
      await tapAndWaitMs(widgetTester, cardMenuButton, 0);

      final deleteHubMenuItem = find.byKey(const ValueKey('menuItem.deleteHub'));
      await pumpUntilFound(widgetTester, deleteHubMenuItem);
      await tapAndWaitMs(widgetTester, deleteHubMenuItem, 0);
      final deleteHubButton = find.byKey(const ValueKey('button.deleteHub'));
      expect(deleteHubButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, deleteHubButton, 0);

      await Future.delayed(const Duration(seconds: 1));
    });
  });
}
