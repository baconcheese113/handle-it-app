import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/register.dart';
import 'package:handle_it/home.dart';

class Login extends StatefulWidget {
  final Function reinitialize;
  const Login({Key key, this.reinitialize}) : super(key: key);
  static String routeName = '/login';

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";

  void switchToRegister() async {
    await Navigator.pushReplacementNamed(context, Register.routeName);
  }

  void switchToHome(String newToken) async {
    this.widget.reinitialize(newToken);
    await Future.delayed(Duration(seconds: 3));
    await Navigator.pushReplacementNamed(context, Home.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("HandleIt"),
      ),
      body: Mutation(
        options: MutationOptions(
          document: gql(r'''
            mutation loginMutation($email: String!, $password: String!, $fcmToken: String!) {
              loginWithPassword(email: $email, password: $password, fcmToken: $fcmToken)
            }
        '''),
        ),
        builder: (
          RunMutation runMutation,
          QueryResult result,
        ) {
          if (result.isLoading) return Text("Loading...");
          if (result.data != null && result.data.containsKey("loginWithPassword")) {
            switchToHome(result.data['loginWithPassword']);
            return Text("Logging in...");
          }
          return Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                        decoration: const InputDecoration(hintText: "Enter your email"),
                        onChanged: (newVal) => setState(() => _email = newVal)),
                    TextFormField(
                        decoration: const InputDecoration(hintText: "Enter your password"),
                        onChanged: (newVal) => setState(() => _password = newVal)),
                    ElevatedButton(
                      onPressed: () async {
                        if (_email.length < 3 || _password.length < 3) return; // TODO validate
                        final fcmToken = await FirebaseMessaging.instance.getToken();
                        runMutation({"email": _email, "password": _password, "fcmToken": fcmToken});
                      },
                      child: Text("Login"),
                    )
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: switchToRegister,
                child: Text("Create an account"),
              ),
              if (result.hasException) Text(result.exception.toString()),
            ],
          );
        },
      ),
    );
  }
}
