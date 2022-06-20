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

import 'feed/add_wizards/add_vehicle_wizard_content.dart';

final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();

const String TAPPED_NOTIFICATION = "tapped_notification";

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool hubIsNearby = false;
  if (await flutterBlue.isOn) {
    await for (final r
        in flutterBlue.scan(timeout: const Duration(seconds: 2), withServices: [Guid(HUB_SERVICE_UUID)])) {
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}");
      if (r.rssi.abs() < 75) hubIsNearby = true;
      flutterBlue.stopScan();
      break;
    }
    if (hubIsNearby) {
      print("Hub is nearby so discarding notification");
      return;
    }
  }
  print("trying to show notification");
  const AndroidNotificationDetails androidSpecifics = AndroidNotificationDetails("channel_id", "channel_name",
      channelDescription: "Test bed for all dem notifications",
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      showWhen: true);
  const NotificationDetails platformSpecifics = NotificationDetails(android: androidSpecifics);
  await localNotifications.show(DateTime.now().second, message.data['title'], message.data['body'], platformSpecifics,
      payload: TAPPED_NOTIFICATION);
  print("showed notification");
}

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final NotificationAppLaunchDetails? launchDetails = await localNotifications.getNotificationAppLaunchDetails();
  String initialRoute = launchDetails?.didNotificationLaunchApp ?? false ? ShowAlert.routeName : Login.routeName;
  print("didNotificationLaunchApp: ${launchDetails?.didNotificationLaunchApp}, initialRoute: $initialRoute");

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final pushNotificationService = PushNotificationService(_firebaseMessaging);
  // pushNotificationService.initialize();

  // initialize the plugin. app_icon needs to be added as a drawable resource
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings("app_icon");
  const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initializationSettings, onSelectNotification: (String? payload) async {
    initialRoute = Login.routeName;
    if (payload != null) selectNotificationSubject.add(payload);
    print("Notification payload: $payload, and initialRoute: $initialRoute");
  });
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Using HiveStore for persistence
  await initHiveForFlutter();

  // try to log in with existing token
  // if still not logged in, login route
  runApp(App(initialRoute: initialRoute, selectNotificationSubject: selectNotificationSubject));
}
