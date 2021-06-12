import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/settings/addTestHub.dart';
import 'package:handle_it/utils.dart';

class Settings extends StatefulWidget {
  final user;
  final Function reinitialize;
  const Settings(this.user, this.reinitialize, {Key key}) : super(key: key);

  static final settingsFragment = addFragments(gql(r"""
    fragment settings_user on User {
      id
      email
      firstName
      ...addTestHub_user
    }
  """), [AddTestHub.addTestHubFragment]);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _firstName = "";

  @override
  void initState() {
    _firstName = this.widget.user['firstName'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void logout() async {
      await FlutterSecureStorage().delete(key: 'token');
      this.widget.reinitialize();
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
              ElevatedButton(
                  onPressed:
                      _firstName == this.widget.user['firstName'] ? null : () => runMutation({'firstName': _firstName}),
                  child: const Text("Update name")),
              ElevatedButton(onPressed: logout, child: const Text("Logout")),
              Padding(padding: EdgeInsets.only(top: 40)),
              Divider(),
              Padding(
                padding: EdgeInsets.only(top: 40, bottom: 20),
                child: Text("Developer tools", textScaleFactor: 1.4),
              ),
              AddTestHub(user: this.widget.user),
            ],
          ),
        );
      },
    );
  }
}
