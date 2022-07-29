import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handle_it/auth/register.dart';
import 'package:handle_it/auth/~graphql/__generated__/login.mutation.graphql.dart';
import 'package:handle_it/common/loading.dart';
import 'package:handle_it/home.dart';
import 'package:vrouter/vrouter.dart';

class Login extends StatefulWidget {
  final Function reinitialize;
  const Login({Key? key, required this.reinitialize}) : super(key: key);
  static const routeName = '/login';

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";

  void _switchToRegister() {
    context.vRouter.to(Register.routeName, isReplacement: true);
  }

  void _switchToHome(String newToken) async {
    print("switchToHome called");
    await const FlutterSecureStorage().write(key: 'token', value: newToken);
    widget.reinitialize(newToken);
    context.vRouter.to(Home.routeName, isReplacement: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("HandleIt"),
      ),
      body: Mutation$Login$Widget(
        builder: (runMutation, result) {
          print("Render of login called");
          if (result == null || result.isLoading) return const Loading();
          if (result.data != null && result.data!.containsKey("loginWithPassword")) {
            _switchToHome(result.data!['loginWithPassword']);
            return const Loading();
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
                      onChanged: (newVal) => setState(() => _email = newVal),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(hintText: "Enter your password"),
                      onChanged: (newVal) => setState(() => _password = newVal),
                      obscureText: true,
                    ),
                    ElevatedButton(
                      key: const ValueKey('button.login'),
                      onPressed: () async {
                        if (_email.length < 3 || _password.length < 3) return; // TODO validate
                        final fcmToken = await FirebaseMessaging.instance.getToken();
                        runMutation(
                          Variables$Mutation$Login(
                            email: _email,
                            password: _password,
                            fcmToken: fcmToken!,
                          ),
                        );
                      },
                      child: const Text("Login"),
                    )
                  ],
                ),
              ),
              ElevatedButton(
                key: const ValueKey('button.switchToRegister'),
                onPressed: _switchToRegister,
                child: const Text("Create an account"),
              ),
              if (result.hasException) Text(result.exception.toString()),
            ],
          );
        },
      ),
    );
  }
}
