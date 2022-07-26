import 'package:flutter/material.dart';
import 'package:handle_it/network/member/~graphql/__generated__/member.fragments.graphql.dart';
import 'package:handle_it/network/member/~graphql/__generated__/network_member_delete.mutation.graphql.dart';

class NetworkMemberDelete extends StatelessWidget {
  final Fragment$networkMemberDelete_member memberFrag;
  const NetworkMemberDelete({Key? key, required this.memberFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation$DeleteNetworkMember$Widget(builder: (runMutation, result) {
      return IconButton(
        onPressed: () {
          runMutation(Variables$Mutation$DeleteNetworkMember(
            networkMemberId: memberFrag.id,
          ));
        },
        icon: const Icon(Icons.delete),
      );
    });
  }
}
