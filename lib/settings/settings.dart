import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/settings/add_test_hub.dart';
import 'package:handle_it/settings/notification_settings.dart';
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  final SettingsUserMixin userFrag;
  final Function reinitialize;
  const Settings(this.userFrag, this.reinitialize, {Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _firstName = "";

  @override
  void initState() {
    _firstName = widget.userFrag.firstName ?? "";
    super.initState();
  }

  void _removeTutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(introTutPrefKey)) return;
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
      options: MutationOptions(
        document: SETTINGS_UPDATE_USER_MUTATION_DOCUMENT,
        operationName: SETTINGS_UPDATE_USER_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        final canUpdateName = _firstName != widget.userFrag.firstName;
        handleUpdateName() async {
          if (!canUpdateName) return;
          await runMutation(
            SettingsUpdateUserArguments(firstName: _firstName).toJson(),
          ).networkResult;
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  readOnly: true,
                  initialValue: widget.userFrag.email,
                  decoration: const InputDecoration(hintText: 'Enter your email'),
                  validator: (String? value) {
                    if (EmailValidator.validate(value ?? "")) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: widget.userFrag.firstName,
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
                  onPressed: canUpdateName ? handleUpdateName : null,
                  child: const Text("Update name"),
                ),
                ElevatedButton(onPressed: logout, child: const Text("Logout")),
                const Padding(padding: EdgeInsets.only(top: 20)),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text("Notification type", textScaleFactor: 1.4),
                ),
                NotificationSettings(user: widget.userFrag as NotificationSettingsUserMixin),
                const Padding(padding: EdgeInsets.only(top: 40)),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 20),
                  child: Text("Developer tools", textScaleFactor: 1.4),
                ),
                AddTestHub(user: widget.userFrag as AddTestHubUserMixin),
                Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: _removeTutPrefs,
                      child: const Text("Remove Tut Prefs"),
                    ))
              ],
            ),
          ),
        );
      },
    );
  }
}
