import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/app.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/notifications/show_alert.dart';
import 'package:rxdart/subjects.dart';

final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();

const String TAPPED_NOTIFICATION = "tapped_notification";

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("trying to show notification");
  const AndroidNotificationDetails androidSpecifics = AndroidNotificationDetails(
      "channel_id", "channel_name", "Test bed for all dem notifications",
      importance: Importance.max, priority: Priority.max, fullScreenIntent: true, showWhen: true);
  const NotificationDetails platformSpecifics = NotificationDetails(android: androidSpecifics);
  await localNotifications.show(DateTime.now().second, message.data['title'], message.data['body'], platformSpecifics,
      payload: TAPPED_NOTIFICATION);
  print("showed notification");
}

void main() async {
  await DotEnv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final NotificationAppLaunchDetails launchDetails = await localNotifications.getNotificationAppLaunchDetails();
  String initialRoute = launchDetails?.didNotificationLaunchApp ?? false ? ShowAlert.routeName : Login.routeName;
  print("didNotificationLaunchApp: ${launchDetails?.didNotificationLaunchApp}, initialRoute: $initialRoute");

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final pushNotificationService = PushNotificationService(_firebaseMessaging);
  // pushNotificationService.initialize();

  // initialize the plugin. app_icon needs to be added as a drawable resource
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings("app_icon");
  final InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initializationSettings, onSelectNotification: (String payload) async {
    initialRoute = Login.routeName;
    selectNotificationSubject.add(payload);
    print("Notification payload: $payload, and initialRoute: $initialRoute");
  });
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Using HiveStore for persistence
  await initHiveForFlutter();

  // try to log in with existing token
  // if still not logged in, login route
  runApp(App(initialRoute: initialRoute, selectNotificationSubject: selectNotificationSubject));
}
