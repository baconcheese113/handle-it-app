import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/auth/~graphql/__generated__/register.mutation.graphql.dart';
import 'package:handle_it/common/loading.dart';
import 'package:handle_it/home.dart';
import 'package:vrouter/vrouter.dart';

class Register extends StatefulWidget {
  final Function reinitialize;
  const Register({Key? key, required this.reinitialize}) : super(key: key);
  static const routeName = '/register';

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String _firstName = "";
  String _lastName = "";

  void _switchToLogin() {
    context.vRouter.to(Login.routeName, isReplacement: true);
  }

  Future<void> _switchToHome(String newToken) async {
    await const FlutterSecureStorage().write(key: 'token', value: newToken);
    await widget.reinitialize(newToken);
    context.vRouter.to(Home.routeName, isReplacement: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("HandleIt"),
      ),
      body: Mutation$register$Widget(builder: (runMutation, result) {
        if (result == null || result.isLoading) return const Loading();
        if (result.data != null && result.data!.containsKey("registerWithPassword")) {
          _switchToHome(result.data!['registerWithPassword']);
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
                    key: const ValueKey('button.register'),
                    onPressed: () async {
                      if (_email.length < 3 || _password.length < 3) return; // TODO validate
                      final fcmToken = await FirebaseMessaging.instance.getToken();
                      await runMutation(
                        Variables$Mutation$register(
                          email: _email,
                          password: _password,
                          fcmToken: fcmToken!,
                          firstName: _firstName,
                          lastName: _lastName,
                        ),
                      ).networkResult;
                    },
                    child: const Text("Register"),
                  ),
                  if (result.hasException) Text(result.exception.toString()),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _switchToLogin,
              child: const Text("Already have an account?"),
            ),
          ],
        );
      }),
    );
  }
}
