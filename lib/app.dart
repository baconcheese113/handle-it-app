import 'package:flutter/material.dart';
import 'package:handle_it/authentication_page.dart';
import 'package:handle_it/client_provider.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/show_alert.dart';
import 'package:rxdart/subjects.dart';

class App extends StatefulWidget {
  final String initialRoute;
  final BehaviorSubject<String> selectNotificationSubject;
  const App({Key key, this.initialRoute, this.selectNotificationSubject}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    this.widget.selectNotificationSubject.stream.listen((String payload) async {
      print("heard $payload from the stream");
      await Navigator.pushNamed(context, ShowAlert.routeName);
    });
  }

  @override
  void dispose() {
    this.widget.selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClientProvider(
      child: MaterialApp(
        title: 'HandleIt',
        initialRoute: this.widget.initialRoute,
        routes: <String, WidgetBuilder>{
          Home.routeName: (_) => Home(),
          ShowAlert.routeName: (_) => ShowAlert(),
          AuthenticationPage.routeName: (_) => AuthenticationPage(),
        },
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
      ),
    );
  }
}
