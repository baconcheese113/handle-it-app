import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handle_it/feed_home.dart';

class BackgroundClass {
  MethodChannel platform;
  BackgroundClass(platform) {
    this.platform = platform;
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.notification.title} ${message.notification.body}");
    String response = "";
    try {
      final int result = await this.platform.invokeMethod('getBatteryLevel');
      response = "Response: $result";
    } on PlatformException catch (e) {
      response = "Failed to Invoke: '${e.message}'.";
    }
    print(response);
    // AudioPlayer audioPlayer = AudioPlayer();
    // await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse("asset:///assets/audio/alarm.mp3"))).catchError((error) {
    //   print("An error occured $error");
    // });
    // audioPlayer.play();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  const platform = const MethodChannel('flutter.native/helper');
  BackgroundClass backgroundClass = BackgroundClass(platform);
  FirebaseMessaging.onBackgroundMessage(backgroundClass._firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final pushNotificationService = PushNotificationService(_firebaseMessaging);

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
