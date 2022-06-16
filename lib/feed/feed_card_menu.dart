import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_sensor_wizard.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedCardMenu extends StatefulWidget {
  final Map<String, dynamic> hub;
  final Function onDelete;
  const FeedCardMenu({Key? key, required this.hub, required this.onDelete}) : super(key: key);

  @override
  State<FeedCardMenu> createState() => _FeedCardMenuState();
}

class _FeedCardMenuState extends State<FeedCardMenu> {
  @override
  Mutation build(BuildContext context) {
    void handleAddSensor() {
      if (mounted) {
        Navigator.pushNamed(context, AddSensorWizard.routeName, arguments: {'hubId': widget.hub['id']});
      }
    }

    return Mutation(
      options: MutationOptions(document: addFragments(gql(r'''
        mutation feedCardDeleteMutation($id: ID!) {
          deleteHub(id: $id) {
            id
            ...feedCard_hub
          }
        }
      '''), [FeedCard.fragment])),
      builder: (
        RunMutation runMutation,
        QueryResult? result,
      ) {
        void handleDelete() {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text("Delete Hub"),
              content: const Text("This will remove this hub and it's associated sensors from your account."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await runMutation({'id': widget.hub['id']}).networkResult;
                    widget.onDelete();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Delete"),
                )
              ],
            ),
          );
        }

        return PopupMenuButton(
          child: const Icon(Icons.more_vert),
          onSelected: (idx) {
            if (idx == 0) handleAddSensor();
            if (idx == 1) handleDelete();
          },
          itemBuilder: (menuContext) => [
            const PopupMenuItem(
              value: 0,
              child: ListTile(leading: Icon(Icons.add), title: Text("Add Sensor")),
            ),
            const PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            )
          ],
        );
      },
    );
  }
}
