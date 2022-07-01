import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMemberUpdate extends StatefulWidget {
  final NetworkMemberUpdateMemberMixin memberFrag;
  const NetworkMemberUpdate({Key? key, required this.memberFrag}) : super(key: key);

  @override
  State<NetworkMemberUpdate> createState() => _NetworkMemberUpdateState();
}

class _NetworkMemberUpdateState extends State<NetworkMemberUpdate> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: UPDATE_NETWORK_MEMBER_MUTATION_DOCUMENT,
        operationName: UPDATE_NETWORK_MEMBER_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        void handleEdit() {
          RoleType curRole = widget.memberFrag.role;
          showDialog(
            context: context,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("Update Network Member"),
                    content: DropdownButton<RoleType>(
                      hint: Text(curRole.name),
                      onChanged: (newValue) => setState(() => curRole = newValue!),
                      items: [RoleType.member, RoleType.owner]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.name),
                            ),
                          )
                          .toList(),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                      TextButton(
                        onPressed: curRole != widget.memberFrag.role
                            ? () async {
                                final mutation = await runMutation(
                                  UpdateNetworkMemberArguments(
                                    networkMemberId: widget.memberFrag.id,
                                    role: curRole,
                                  ).toJson(),
                                ).networkResult;
                                if (mutation != null && mutation.isNotLoading && !mutation.hasException) {
                                  if (mounted) Navigator.of(dialogContext).pop();
                                }
                              }
                            : null,
                        child: const Text("Update"),
                      )
                    ],
                  );
                },
              );
            },
          );
        }

        return IconButton(
          onPressed: handleEdit,
          icon: const Icon(Icons.edit),
        );
      },
    );
  }
}
