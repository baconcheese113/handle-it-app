import 'package:flutter/material.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_join.mutation.graphql.dart';
import 'package:vrouter/vrouter.dart';

class NetworkMembersJoin extends StatefulWidget {
  const NetworkMembersJoin({Key? key}) : super(key: key);

  @override
  State<NetworkMembersJoin> createState() => _NetworkMembersJoinState();
}

class _NetworkMembersJoinState extends State<NetworkMembersJoin> {
  @override
  Widget build(BuildContext context) {
    return Mutation$RequestNetworkMembership$Widget(builder: (runMutation, result) {
      void handleJoin() {
        String name = "";
        String exceptions = '';
        showDialog(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text("Enter Network Name"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: const ValueKey('input.networkName'),
                      onChanged: (String n) => name = n,
                    ),
                    if (exceptions.isNotEmpty) Text(exceptions),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => dialogContext.vRouter.pop(),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    key: const ValueKey('button.join'),
                    onPressed: () async {
                      final mutation = await runMutation(
                        Variables$Mutation$RequestNetworkMembership(
                          networkName: name,
                        ),
                      ).networkResult;
                      if (mutation != null && mutation.isNotLoading && !mutation.hasException) {
                        // onNetworkAdded("Network created successfully, refresh to view");
                        dialogContext.vRouter.pop();
                      } else if (mutation?.hasException ?? false) {
                        setState(() => exceptions = mutation!.exception!.graphqlErrors[0].message);
                      }
                    },
                    child: const Text("Join"),
                  )
                ],
              );
            });
          },
        );
      }

      return TextButton(
        key: const ValueKey("button.joinNetwork"),
        onPressed: handleJoin,
        child: const Text("Join Network"),
      );
    });
  }
}
