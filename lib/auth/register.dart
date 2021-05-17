import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/home.dart';

class Register extends StatefulWidget {
  final Function reinitialize;
  const Register({Key key, this.reinitialize}) : super(key: key);
  static String routeName = '/register';

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String _firstName = "";
  String _lastName = "";

  void switchToLogin() async {
    await Navigator.pushReplacementNamed(context, Login.routeName);
  }

  Future<void> switchToHome(String newToken) async {
    await FlutterSecureStorage().write(key: 'token', value: newToken);
    await this.widget.reinitialize(newToken);
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
            mutation registerMutation($email: String!, $password: String!, $fcmToken: String!, $firstName: String, $lastName: String) {
              registerWithPassword(email: $email, password: $password, fcmToken: $fcmToken, firstName: $firstName, lastName: $lastName)
            }
        '''),
          ),
          builder: (
            RunMutation runMutation,
            QueryResult result,
          ) {
            if (result.isLoading) return Text("Loading...");
            if (result.data != null && result.data.containsKey("registerWithPassword")) {
              switchToHome(result.data['registerWithPassword']);
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
                        onChanged: (newVal) => setState(() => _password = newVal),
                        obscureText: true,
                      ),
                      TextFormField(
                          decoration: const InputDecoration(hintText: "Enter your first name (optional)"),
                          onChanged: (newVal) => setState(() => _firstName = newVal)),
                      TextFormField(
                          decoration: const InputDecoration(hintText: "Enter your last name (optional)"),
                          onChanged: (newVal) => setState(() => _lastName = newVal)),
                      ElevatedButton(
                        onPressed: () async {
                          if (_email.length < 3 || _password.length < 3) return; // TODO validate
                          final fcmToken = await FirebaseMessaging.instance.getToken();
                          runMutation({
                            "email": _email,
                            "fcmToken": fcmToken,
                            "password": _password,
                            "firstName": _firstName,
                            "lastName": _lastName,
                          });
                        },
                        child: Text("Register"),
                      ),
                      if (result.hasException) Text(result.exception.toString()),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: switchToLogin,
                  child: Text("Already have an account?"),
                ),
              ],
            );
          }),
    );
  }
}
