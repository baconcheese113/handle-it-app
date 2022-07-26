import 'package:flutter/material.dart';
import 'package:handle_it/graphql/__generated__/schema.graphql.dart';
import 'package:handle_it/network/member/~graphql/__generated__/member.fragments.graphql.dart';
import 'package:handle_it/network/member/~graphql/__generated__/network_member_update.mutation.graphql.dart';

class NetworkMemberUpdate extends StatefulWidget {
  final Fragment$networkMemberUpdate_member memberFrag;
  const NetworkMemberUpdate({Key? key, required this.memberFrag}) : super(key: key);

  @override
  State<NetworkMemberUpdate> createState() => _NetworkMemberUpdateState();
}

class _NetworkMemberUpdateState extends State<NetworkMemberUpdate> {
  @override
  Widget build(BuildContext context) {
    return Mutation$UpdateNetworkMember$Widget(
      builder: (runMutation, result) {
        void handleEdit() {
          Enum$RoleType curRole = widget.memberFrag.role;
          showDialog(
            context: context,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("Update Network Member"),
                    content: DropdownButton<Enum$RoleType>(
                      hint: Text(curRole.name),
                      onChanged: (newValue) => setState(() => curRole = newValue!),
                      items: [Enum$RoleType.member, Enum$RoleType.owner]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.name),
                            ),
                          )
                          .toList(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: curRole != widget.memberFrag.role
                            ? () async {
                                final mutation = await runMutation(
                                  Variables$Mutation$UpdateNetworkMember(
                                    networkMemberId: widget.memberFrag.id,
                                    role: curRole,
                                  ),
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
