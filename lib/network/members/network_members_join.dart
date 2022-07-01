import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMembersJoin extends StatefulWidget {
  const NetworkMembersJoin({Key? key}) : super(key: key);

  @override
  State<NetworkMembersJoin> createState() => _NetworkMembersJoinState();
}

class _NetworkMembersJoinState extends State<NetworkMembersJoin> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
        options: MutationOptions(
          document: REQUEST_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT,
          operationName: REQUEST_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT_OPERATION_NAME,
        ),
        builder: (runMutation, result) {
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
                        TextFormField(onChanged: (String n) => name = n),
                        if (exceptions.isNotEmpty) Text(exceptions),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                      TextButton(
                        onPressed: () async {
                          final mutation = await runMutation(
                            RequestNetworkMembershipArguments(
                              networkName: name,
                            ).toJson(),
                          ).networkResult;
                          if (mutation != null && mutation.isNotLoading && !mutation.hasException) {
                            // onNetworkAdded("Network created successfully, refresh to view");
                            if (mounted) Navigator.of(dialogContext).pop();
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

          return TextButton(onPressed: handleJoin, child: const Text("Join Network"));
        });
  }
}
