import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/settings/add_test_hub.dart';
import 'package:handle_it/settings/notification_settings.dart';
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:handle_it/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function reinitialize;
  const Settings(this.user, this.reinitialize, {Key? key}) : super(key: key);

  static final fragment = addFragments(gql(r"""
    fragment settings_user on User {
      id
      email
      firstName
      ...addTestHub_user
      ...notificationSettings_user
    }
  """), [AddTestHub.fragment, NotificationSettings.fragment]);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _firstName = "";

  @override
  void initState() {
    _firstName = widget.user['firstName'];
    super.initState();
  }

  void removeTutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(introTutPrefKey)) return null;
    await prefs.remove(introTutPrefKey);
  }

  @override
  Widget build(BuildContext context) {
    void logout() async {
      await const FlutterSecureStorage().delete(key: 'token');
      widget.reinitialize();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Login.routeName);
    }

    return Mutation(
      options: MutationOptions(document: gql(r'''
          mutation settingsMutation($firstName: String!) {
            updateUser(firstName: $firstName) {
              id
              firstName
            }
          }
        ''')),
      builder: (
        RunMutation runMutation,
        QueryResult? result,
      ) {
        print("building with ${widget.user}");
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  readOnly: true,
                  initialValue: widget.user['email'],
                  decoration: const InputDecoration(hintText: 'Enter your email'),
                  validator: (String? value) {
                    if (EmailValidator.validate(value ?? "")) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: widget.user['firstName'],
                  decoration: const InputDecoration(hintText: 'Enter your first name'),
                  onChanged: (newValue) => setState(() => _firstName = newValue),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid name';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                    onPressed:
                        _firstName == widget.user['firstName'] ? null : () => runMutation({'firstName': _firstName}),
                    child: const Text("Update name")),
                ElevatedButton(onPressed: logout, child: const Text("Logout")),
                const Padding(padding: EdgeInsets.only(top: 20)),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text("Notification type", textScaleFactor: 1.4),
                ),
                NotificationSettings(user: widget.user),
                const Padding(padding: EdgeInsets.only(top: 40)),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 20),
                  child: Text("Developer tools", textScaleFactor: 1.4),
                ),
                AddTestHub(user: widget.user),
                Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(onPressed: removeTutPrefs, child: const Text("Remove Tut Prefs")))
              ],
            ),
          ),
        );
      },
    );
  }
}
