import 'package:flutter/material.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_create.mutation.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_tab.query.graphql.dart';

class NetworkCreate extends StatefulWidget {
  const NetworkCreate({Key? key}) : super(key: key);

  @override
  State<NetworkCreate> createState() => _NetworkCreateState();
}

class _NetworkCreateState extends State<NetworkCreate> {
  @override
  Widget build(BuildContext context) {
    void onNetworkAdded(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Mutation$CreateNetwork$Widget(options: WidgetOptions$Mutation$CreateNetwork(
      update: (cache, result) {
        if (result?.data == null) return;
        final network = result!.parsedData!.createNetwork!;
        final request = Options$Query$NetworkMembersTab().asRequest;
        final readQuery = cache.readQuery(request);
        if (readQuery == null) return;
        final map = Query$NetworkMembersTab.fromJson(readQuery);
        map.viewer.networks.add(Query$NetworkMembersTab$viewer$networks.fromJson(network.toJson()));
        cache.writeQuery(request, data: map.toJson(), broadcast: true);
      },
    ), builder: (runMutation, result) {
      void handleCreateNetwork() {
        String name = "";
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text("Enter Network Name"),
              content: TextFormField(
                key: const ValueKey('input.networkName'),
                onChanged: (String n) => name = n,
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                TextButton(
                  key: const ValueKey('button.create'),
                  onPressed: () async {
                    final mutation = await runMutation(
                      Variables$Mutation$CreateNetwork(
                        name: name,
                      ),
                    ).networkResult;
                    if (mutation != null && mutation.isNotLoading && !mutation.hasException) {
                      onNetworkAdded("Network created successfully");
                    }
                    if (mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Create"),
                )
              ],
            );
          },
        );
      }

      return TextButton(
        key: const ValueKey('button.createNetwork'),
        onPressed: handleCreateNetwork,
        child: const Text("Create Network"),
      );
    });
  }
}
