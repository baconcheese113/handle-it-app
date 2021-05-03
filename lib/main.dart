import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:handle_it/feed_home.dart';
import 'package:handle_it/show_alert.dart';
import 'package:rxdart/subjects.dart';

final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("trying to show notification");
  const AndroidNotificationDetails androidSpecifics = AndroidNotificationDetails(
      "channel_id", "channel_name", "Test bed for all dem notifications",
      importance: Importance.max, priority: Priority.max, fullScreenIntent: true, showWhen: true);
  const NotificationDetails platformSpecifics = NotificationDetails(android: androidSpecifics);
  await localNotifications.show(DateTime.now().second, "Plain title", "Plain body", platformSpecifics,
      payload: "item x");
  print("showed notification");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final NotificationAppLaunchDetails launchDetails = await localNotifications.getNotificationAppLaunchDetails();
  String initialRoute = launchDetails?.didNotificationLaunchApp ?? false ? ShowAlert.routeName : Home.routeName;
  print("didNotificationLaunchApp: ${launchDetails?.didNotificationLaunchApp}, initialRoute: $initialRoute");

  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final pushNotificationService = PushNotificationService(_firebaseMessaging);
  // pushNotificationService.initialize();

  // initialize the plugin. app_icon needs to be added as a drawable resource
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings("app_icon");
  final InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initializationSettings, onSelectNotification: (String payload) async {
    initialRoute = ShowAlert.routeName;
    selectNotificationSubject.add(payload);
    print("Notification payload: $payload, and initialRoute: $initialRoute");
  });
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    MaterialApp(
      title: 'HandleIt',
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        Home.routeName: (_) => Home(),
        ShowAlert.routeName: (_) => ShowAlert(),
      },
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
    ),
  );
}

class Home extends StatefulWidget {
  static const String routeName = "/home";
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    selectNotificationSubject.stream.listen((String payload) async {
      print("heard $payload from the stream");
      await Navigator.pushNamed(context, ShowAlert.routeName);
    });
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // pushNotificationService.initialize();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("HandleIt"),
      ),
      body: FeedHome(),
    );
  }
}
