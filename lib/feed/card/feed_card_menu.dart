import 'package:flutter/material.dart';
import 'package:handle_it/feed/add_wizards/add_sensor_wizard.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card_menu.mutation.graphql.dart';
import 'package:handle_it/feed/vehicle/vehicle_screen.dart';
import 'package:vrouter/vrouter.dart';

class FeedCardMenu extends StatefulWidget {
  final Fragment$feedCardMenu_hub hubFrag;
  final Function onDelete;
  const FeedCardMenu({Key? key, required this.hubFrag, required this.onDelete}) : super(key: key);

  @override
  State<FeedCardMenu> createState() => _FeedCardMenuState();
}

class _FeedCardMenuState extends State<FeedCardMenu> {
  @override
  Widget build(BuildContext context) {
    void handleEditVehicleDetails() {
      context.vRouter.to(
        "${VehicleScreen.routeName}/${widget.hubFrag.id}",
      );
    }

    void handleAddSensor() {
      context.vRouter.to(
        AddSensorWizard.routeName,
        queryParameters: {'hubId': widget.hubFrag.id.toString()},
      );
    }

    return Mutation$feedCardDelete$Widget(
      builder: (runMutation, result) {
        void handleDelete() {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text("Delete Hub"),
              content: const Text("This will remove this hub and it's associated sensors from your account."),
              actions: [
                TextButton(onPressed: () => context.vRouter.pop(), child: const Text('Cancel')),
                TextButton(
                  key: const ValueKey("button.deleteHub"),
                  onPressed: () async {
                    await runMutation(
                      Variables$Mutation$feedCardDelete(
                        id: "${widget.hubFrag.id}",
                      ),
                    ).networkResult;
                    widget.onDelete();
                    if (mounted) context.vRouter.pop();
                  },
                  child: const Text("Delete"),
                )
              ],
            ),
          );
        }

        return PopupMenuButton(
          key: const ValueKey("button.cardMenu"),
          child: const Icon(Icons.more_vert),
          onSelected: (idx) {
            if (idx == 0) handleEditVehicleDetails();
            if (idx == 1) handleAddSensor();
            if (idx == 2) handleDelete();
          },
          itemBuilder: (menuContext) => [
            const PopupMenuItem(
              value: 0,
              child: ListTile(leading: Icon(Icons.edit), title: Text("Edit vehicle details")),
            ),
            const PopupMenuItem(
              key: ValueKey("menuItem.addSensor"),
              value: 1,
              child: ListTile(leading: Icon(Icons.add), title: Text("Add Sensor")),
            ),
            const PopupMenuItem(
              key: ValueKey("menuItem.deleteHub"),
              value: 2,
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
