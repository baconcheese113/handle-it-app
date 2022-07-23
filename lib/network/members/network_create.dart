import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

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

    return Mutation(
        options: MutationOptions(
          document: CREATE_NETWORK_MUTATION_DOCUMENT,
          operationName: CREATE_NETWORK_MUTATION_DOCUMENT_OPERATION_NAME,
          update: (cache, result) {
            if (result?.data == null) return;
            final data = CreateNetwork$Mutation.fromJson(result!.data!).createNetwork!;
            final query = NetworkMembersTabQuery();
            final request = QueryOptions(document: query.document).asRequest;
            final readQuery = cache.readQuery(request);
            if (readQuery == null) return;
            final map = query.parse(readQuery);
            map.viewer.networks.add(NetworkMembersTab$Query$Viewer$Networks.fromJson(data.toJson()));
            cache.writeQuery(request, data: map.toJson(), broadcast: true);
          },
        ),
        builder: (runMutation, result) {
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
                          CreateNetworkArguments(
                            name: name,
                          ).toJson(),
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
