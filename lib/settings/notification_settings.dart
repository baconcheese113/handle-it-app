import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NotificationSettings extends StatefulWidget {
  final Map<String, dynamic> user;
  const NotificationSettings({Key? key, required this.user}) : super(key: key);

  static final fragment = gql(r'''
    fragment notificationSettings_user on User {
      id
      defaultFullNotification
    }
  ''');
  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(document: gql(r'''
          mutation updateNotificationSettings($defaultFullNotification: Boolean!) {
            updateUser(defaultFullNotification: $defaultFullNotification) {
              id
              defaultFullNotification
            }
          }
        ''')),
      builder: (
        RunMutation runMutation,
        QueryResult? result,
      ) {
        void commitChange(bool defaultFullNotification) async {
          if (_loading || defaultFullNotification == widget.user['defaultFullNotification']) return;
          setState(() => _loading = true);
          await runMutation({
            'defaultFullNotification': defaultFullNotification,
          }).networkResult;
          setState(() => _loading = false);
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => ToggleButtons(
                constraints: BoxConstraints.expand(width: constraints.maxWidth / 2 - 2, height: 50),
                isSelected: widget.user['defaultFullNotification'] ? [false, true] : [true, false],
                onPressed: _loading ? null : (idx) => commitChange(idx == 1),
                children: const [
                  Text("Silent"),
                  Text("Full"),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
