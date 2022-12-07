import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';
import 'package:handle_it/main.dart' as app;
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_ble_provider.dart';
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
      final mockBleProvider = FakeBleProvider();
      app.main(bleProvider: mockBleProvider);
      await login(widgetTester);
      final faker = Faker();

      const MethodChannel('plugins.flutter.io/google_maps_0').setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'map#waitForMap') {
          return null;
        }
        return null;
      });
      await Future.delayed(const Duration(seconds: 1));

      final networkNavIcon = find.byKey(const ValueKey('navIcon.network'));
      await pumpUntilFound(widgetTester, networkNavIcon);
      expect(networkNavIcon, findsOneWidget);
      await tapAndWaitMs(widgetTester, networkNavIcon, 0);

      final membersTab = find.byKey(const ValueKey('tab.members'));
      await pumpUntilFound(widgetTester, membersTab);
      expect(membersTab, findsOneWidget);
      await tapAndWaitMs(widgetTester, membersTab, 0);

      final createNetworkButton = find.byKey(const ValueKey('button.createNetwork'));
      expect(createNetworkButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, createNetworkButton, 0);

      final createNetworkName = faker.address.neighborhood();
      final networkNameInput = find.byKey(const ValueKey('input.networkName'));
      expect(networkNameInput, findsOneWidget);
      await widgetTester.enterText(networkNameInput, createNetworkName);

      final createButton = find.byKey(const ValueKey('button.create'));
      expect(createButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, createButton, 0);

      final networksList = find.byKey(const ValueKey('list.networks'));
      expect(networksList, findsOneWidget);
      await widgetTester.drag(networksList, const Offset(0, 500));
      await widgetTester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 1));
      await widgetTester.pumpAndSettle();

      final createNetworkText = find.text(createNetworkName, skipOffstage: false);
      await pumpUntilFound(widgetTester, createNetworkText);
      expect(createNetworkText, findsOneWidget);
      await widgetTester.ensureVisible(createNetworkText);
      await widgetTester.pumpAndSettle();

      final createNetworkCard = find.widgetWithText(Card, createNetworkName, skipOffstage: false);
      await pumpUntilFound(widgetTester, createNetworkCard);
      expect(createNetworkCard, findsOneWidget);
      await widgetTester.ensureVisible(createNetworkCard);
      await widgetTester.pumpAndSettle();

      final newMemberEmail = faker.internet.email();
      final newMemberInput = find.descendant(
        of: createNetworkCard,
        matching: find.byKey(const ValueKey('input.newMember')),
        skipOffstage: false,
      );
      expect(newMemberInput, findsOneWidget);
      await widgetTester.ensureVisible(newMemberInput);
      await widgetTester.pumpAndSettle();
      await widgetTester.enterText(newMemberInput, newMemberEmail);
      await widgetTester.pumpAndSettle();

      final newMemberButton = find.descendant(
        of: createNetworkCard,
        matching: find.byKey(const ValueKey('button.newMember')),
      );
      expect(newMemberButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, newMemberButton, 0);

      final newMemberText = find.textContaining(newMemberEmail);
      await pumpUntilFound(widgetTester, newMemberText);
      expect(newMemberText, findsOneWidget);

      final deleteNetworkButton = find.descendant(
        of: createNetworkCard,
        matching: find.byKey(const ValueKey('button.deleteNetwork')),
      );
      expect(deleteNetworkButton, findsOneWidget);
      await widgetTester.ensureVisible(deleteNetworkButton);
      await tapAndWaitMs(widgetTester, deleteNetworkButton, 0);

      var client = getClient();
      var res = await client.mutate(MutationOptions(document: gql('''
        mutation RegisterWithPassword {
          registerWithPassword(email: "$newMemberEmail", password: "password", fcmToken: "token")
        }
      ''')));
      final token = res.data!['registerWithPassword'];
      client = getClient(token: token);

      final networkName = faker.address.neighborhood();
      final createNetRes = await client.mutate(MutationOptions(document: gql('''
        mutation CreateNetwork {
          createNetwork(name: "$networkName") {
            id
          }
        }
      ''')));
      final networkId = createNetRes.data!['createNetwork']['id'];

      final joinNetworkButton = find.byKey(const ValueKey('button.joinNetwork'), skipOffstage: false);
      await widgetTester.ensureVisible(joinNetworkButton);
      await tapAndWaitMs(widgetTester, joinNetworkButton, 0);

      final joinNetworkNameInput = find.byKey(const ValueKey('input.networkName'));
      expect(joinNetworkNameInput, findsOneWidget);
      await widgetTester.enterText(joinNetworkNameInput, networkName);

      final joinButton = find.byKey(const ValueKey('button.join'));
      expect(joinButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, joinButton, 0);

      final invitesTab = find.byKey(const ValueKey('tab.invites'));
      expect(invitesTab, findsOneWidget);
      await tapAndWaitMs(widgetTester, invitesTab, 0);

      final invitesList = find.byKey(const ValueKey('list.invites'));
      await pumpUntilFound(widgetTester, invitesList);
      expect(invitesList, findsOneWidget);
      await widgetTester.drag(invitesList, const Offset(0, 500));
      await widgetTester.pumpAndSettle();

      final newRequestCard = find.widgetWithText(Card, networkName);
      await pumpUntilFound(widgetTester, newRequestCard);
      expect(newRequestCard, findsOneWidget);
      final deleteRequestButton = find.descendant(
        of: newRequestCard,
        matching: find.byKey(const ValueKey('button.deleteRequest')),
      );
      expect(deleteRequestButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, deleteRequestButton, 0);

      final memMutation = await client.mutate(MutationOptions(document: gql('''
        mutation CreateNetworkMember {
          createNetworkMember(networkId: $networkId, email: "$TEST_USER_EMAIL", role: owner) {
            id
          }
        }
      ''')));
      expect(memMutation.data!["createNetworkMember"]["id"], isNotNull);

      await widgetTester.drag(invitesList, const Offset(0, 500));
      await widgetTester.pumpAndSettle();

      final newInviteCard = find.widgetWithText(Card, networkName);
      await pumpUntilFound(widgetTester, newInviteCard);
      expect(newInviteCard, findsOneWidget);
      final acceptInvitationButton = find.descendant(
        of: newInviteCard,
        matching: find.byKey(const ValueKey('button.acceptInvitation')),
      );
      expect(acceptInvitationButton, findsOneWidget);
      await tapAndWaitMs(widgetTester, acceptInvitationButton, 0);

      await tapAndWaitMs(widgetTester, membersTab, 0);
      await widgetTester.drag(networksList, const Offset(0, 500));
      await widgetTester.pumpAndSettle();

      final newNetworkCard = find.widgetWithText(Card, networkName, skipOffstage: false);
      await pumpUntilFound(widgetTester, newNetworkCard);
      expect(newNetworkCard, findsOneWidget);
      await widgetTester.ensureVisible(newNetworkCard);

      final newNetworkCardDelete = find.descendant(
        of: newNetworkCard,
        matching: find.byKey(const ValueKey('button.deleteNetwork')),
      );
      await pumpUntilFound(widgetTester, newNetworkCardDelete);
      expect(newNetworkCardDelete, findsOneWidget);
      await widgetTester.ensureVisible(newNetworkCardDelete);
      await tapAndWaitMs(widgetTester, newNetworkCardDelete, 0);
    });
  });
}
