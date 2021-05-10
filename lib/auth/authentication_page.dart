import 'package:flutter/material.dart';
import 'package:handle_it/login.dart';
import 'package:handle_it/register.dart';

class AuthenticationPage extends StatefulWidget {
  final Function reinitialize;
  final Widget child;
  static String routeName = '/auth';
  const AuthenticationPage({Key key, this.reinitialize, this.child}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  bool tryRegister = false;
  String route = Register.routeName;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandleIt',
      initialRoute: route,
      routes: <String, WidgetBuilder>{
        Register.routeName: (_) => Register(reinitialize: this.widget.reinitialize),
        Login.routeName: (_) => Login(reinitialize: this.widget.reinitialize),
      },
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("HandleIt"),
        ),
        body: this.widget.child,
      ),
    );
  }
}
