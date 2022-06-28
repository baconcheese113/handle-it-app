import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/feed/add_wizards/add_sensor_wizard.dart';

class FeedCardMenu extends StatefulWidget {
  final FeedCardMenuHubMixin hubFrag;
  final Function onDelete;
  const FeedCardMenu({Key? key, required this.hubFrag, required this.onDelete}) : super(key: key);

  @override
  State<FeedCardMenu> createState() => _FeedCardMenuState();
}

class _FeedCardMenuState extends State<FeedCardMenu> {
  @override
  Mutation build(BuildContext context) {
    void handleAddSensor() {
      if (mounted) {
        Navigator.pushNamed(context, AddSensorWizard.routeName, arguments: {'hubId': widget.hubFrag.id});
      }
    }

    return Mutation(
      options: MutationOptions(
        document: FEED_CARD_DELETE_MUTATION_DOCUMENT,
        operationName: FEED_CARD_DELETE_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
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
                    await runMutation(
                      FeedCardDeleteArguments(
                        id: "${widget.hubFrag.id}",
                      ).toJson(),
                    ).networkResult;
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
