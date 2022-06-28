import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NotificationSettings extends StatefulWidget {
  final NotificationSettingsUserMixin user;
  const NotificationSettings({Key? key, required this.user}) : super(key: key);

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: UPDATE_NOTIFICATION_SETTINGS_MUTATION_DOCUMENT,
        operationName: UPDATE_NOTIFICATION_SETTINGS_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        void commitChange(bool defaultFullNotification) async {
          if (_loading || defaultFullNotification == widget.user.defaultFullNotification) return;
          setState(() => _loading = true);
          final res = await runMutation(
            UpdateNotificationSettingsArguments(
              defaultFullNotification: defaultFullNotification,
            ).toJson(),
          ).networkResult;
          setState(() => _loading = false);
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => ToggleButtons(
                constraints: BoxConstraints.expand(width: constraints.maxWidth / 2 - 2, height: 50),
                isSelected: widget.user.defaultFullNotification ? [false, true] : [true, false],
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
