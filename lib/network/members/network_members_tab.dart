import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

import 'network_members_list.dart';

class NetworkMembersTab extends StatefulWidget {
  final NetworkMembersTabViewerMixin viewerFrag;
  final Function refetch;
  const NetworkMembersTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  @override
  State<NetworkMembersTab> createState() => _NetworkMembersTabState();
}

class _NetworkMembersTabState extends State<NetworkMembersTab> {
  @override
  Widget build(BuildContext context) {
    final networks = widget.viewerFrag.networks;
    final networksList = [];
    for (final n in networks) {
      networksList.add(NetworkMembersList(networkFrag: n));
    }
    onNetworkAdded(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await widget.refetch();
      },
      child: Mutation(
        options: MutationOptions(
          document: CREATE_NETWORK_MUTATION_DOCUMENT,
          operationName: CREATE_NETWORK_MUTATION_DOCUMENT_OPERATION_NAME,
        ),
        builder: (runMutation, result) {
          void handleCreateNetwork() {
            String name = "";
            showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("Enter Network Name"),
                  content: TextFormField(onChanged: (String n) => name = n),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                    TextButton(
                        onPressed: () async {
                          final mutation = await runMutation(
                            CreateNetworkArguments(
                              name: name,
                            ).toJson(),
                          ).networkResult;
                          if (mutation != null && mutation.isNotLoading && !mutation.hasException) {
                            onNetworkAdded("Network created successfully, refresh to view");
                          }
                          if (mounted) Navigator.of(dialogContext).pop();
                        },
                        child: const Text("Create"))
                  ],
                );
              },
            );
          }

          return SingleChildScrollView(
            child: Column(children: [
              TextButton(onPressed: handleCreateNetwork, child: const Text("Create Network")),
              ...networksList.reversed.toList(),
            ]),
          );
        },
      ),
    );
  }
}
