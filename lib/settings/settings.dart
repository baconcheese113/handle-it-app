import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/login.dart';

class Settings extends StatefulWidget {
  final user;
  const Settings(this.user, {Key key}) : super(key: key);

  static final settingsFragment = gql(r"""
    fragment settingsFragment_user on User {
      id
      email
      firstName
    }
  """);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _firstName = "";

  @override
  Widget build(BuildContext context) {
    // TODO Add authorization to api -- DONE!
    // TODO Refactor routes to be off Viewer -- DONE!
    // TODO Login/Register through app -- DONE!
    // TODO Refactor to scalable login solution
    // TODO Logout through app
    // TODO Add updateUser mutation
    // TODO Get updateUser mutation working here

    void logout() async {
      await FlutterSecureStorage().delete(key: 'token');
      Navigator.pushReplacementNamed(context, Login.routeName);
    }

    return Mutation(
      options: MutationOptions(document: gql(r'''
          mutation updateSettings($data: UpdateUserInfo!) {
            updateUser(data: $data) {
              id
              firstName
            }
          }
        ''')),
      builder: (
        RunMutation runMutation,
        QueryResult result,
      ) {
        print("building with ${this.widget.user}");
        return Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                readOnly: true,
                initialValue: this.widget.user['email'],
                decoration: const InputDecoration(hintText: 'Enter your email'),
                validator: (String value) {
                  if (EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: this.widget.user['firstName'],
                decoration: const InputDecoration(hintText: 'Enter your first name'),
                onChanged: (newValue) => setState(() => _firstName = newValue),
                validator: (String value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid name';
                  }
                  return null;
                },
              ),
              ElevatedButton(onPressed: () => runMutation({'firstName': _firstName}), child: const Text("Submit")),
              ElevatedButton(onPressed: logout, child: const Text("Logout"))
            ],
          ),
        );
      },
    );
  }
}
