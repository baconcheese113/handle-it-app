import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/app.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/notifications/show_alert.dart';
import 'package:rxdart/subjects.dart';

import 'common/ble_provider.dart';

final localNotifications = FlutterLocalNotificationsPlugin();

final selectNotificationSubject = BehaviorSubject<String>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Received RemoteMessage ${message.data.toString()}");
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final data = message.data;
  bool hubIsNearby = false;
  if (await flutterBlue.isOn) {
    await for (final r
        in flutterBlue.scan(timeout: const Duration(seconds: 2), withServices: [Guid(HUB_SERVICE_UUID)])) {
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}, MAC ${r.device.id.id}");
      if (r.device.id.id.toLowerCase() != data["hubSerial"].toString().toLowerCase()) continue;
      // if (r.rssi.abs() < 75) hubIsNearby = true;
      hubIsNearby = true;
      flutterBlue.stopScan();
      break;
    }
    if (hubIsNearby) {
      print("Hub is nearby so discarding notification");
      return;
    }
  }
  const IOSNotificationDetails iosSpecifics = IOSNotificationDetails();
  print("trying to show notification");
  const AndroidNotificationDetails androidSpecifics = AndroidNotificationDetails("channel_id", "channel_name",
      channelDescription: "Test bed for all dem notifications",
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      showWhen: true);
  const NotificationDetails platformSpecifics = NotificationDetails(android: androidSpecifics, iOS: iosSpecifics);
  await localNotifications.show(1, data["title"], data["body"], platformSpecifics, payload: data["eventId"]);
  print("showed notification");
}

void main({BleProvider? bleProvider}) async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); //options: DefaultFirebaseOptions.currentPlatform);

  final NotificationAppLaunchDetails? launchDetails = await localNotifications.getNotificationAppLaunchDetails();
  String initialRoute = launchDetails?.didNotificationLaunchApp ?? false ? ShowAlert.routeName : Login.routeName;
  print(
      "didNotificationLaunchApp: ${launchDetails?.didNotificationLaunchApp}, initialRoute: $initialRoute, payload: ${launchDetails?.payload}");

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final pushNotificationService = PushNotificationService(_firebaseMessaging);
  // pushNotificationService.initialize();

  // initialize the plugin. app_icon needs to be added as a drawable resource
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings("app_icon");
  const IOSInitializationSettings iosSettings = IOSInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  final notificationsReady = await localNotifications.initialize(
    initializationSettings,
    onSelectNotification: (String? payload) async {
      initialRoute = Login.routeName;
      if (payload != null) selectNotificationSubject.add(payload);
      print("Notification payload: $payload, and initialRoute: $initialRoute");
    },
  );
  print("notificationsReady: $notificationsReady");
  await localNotifications.cancelAll();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Using HiveStore for persistence
  await initHiveForFlutter();

  // try to log in with existing token
  // if still not logged in, login route
  runApp(App(
    initialRoute: initialRoute,
    selectNotificationSubject: selectNotificationSubject,
    eventId: launchDetails?.payload,
    bleProvider: bleProvider,
  ));
}
