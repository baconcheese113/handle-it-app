import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:handle_it/feed_home.dart';
import 'package:handle_it/push_notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'notifications', 'High Importance Notifications', 'This channel is used for important notifications.',
  //     importance: Importance.max);
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);

  // const platform = const MethodChannel('samples.flutter.dev/battery');
  // String response = "";
  // try {
  //   final int result = await platform.invokeMethod('getBatteryLevel');
  //   response = "Response: $result";
  // } on PlatformException catch (e) {
  //   response = "Failed to Invoke: '${e.message}'.";
  // }
  // print(response);
}

void main() async {
  print(">>>In main!");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // const platform = const MethodChannel('notifications');
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final pushNotificationService = PushNotificationService(_firebaseMessaging);
  pushNotificationService.initialize();
  // BackgroundClass backgroundClass = BackgroundClass(platform);
  // FirebaseMessaging.onBackgroundMessage(backgroundClass._firebaseMessagingBackgroundHandler);
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // pushNotificationService.initialize();
    return MaterialApp(
      title: 'HandleIt',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("HandleIt"),
        ),
        body: FeedHome(),
      ),
    );
  }
}
