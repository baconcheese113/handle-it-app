import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/login.dart';

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
            mutation registerMutation($email: String!, $password: String!, $firstName: String, $lastName: String) {
              registerWithPassword(email: $email, password: $password, firstName: $firstName, lastName: $lastName)
            }
        '''),
          ),
          builder: (
            RunMutation runMutation,
            QueryResult result,
          ) {
            if (result.isLoading) return Text("Loading...");
            if (result.data != null && result.data.containsKey("registerWithPassword")) {
              this.widget.reinitialize(result.data['registerWithPassword']);
              return Text("Logging in...");
            }
            if (result.hasException) {
              print("Exception: ${result.exception.toString()}");
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
                        onPressed: () {
                          if (_email.length < 3 || _password.length < 3) return; // TODO validate
                          runMutation(
                              {"email": _email, "password": _password, "firstName": _firstName, "lastName": _lastName});
                        },
                        child: Text("Register"),
                      )
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
