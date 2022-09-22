import 'package:flutter/material.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/network_invites_card.mutations.graphql.dart';

class NetworkMemberAccept extends StatelessWidget {
  final int memberId;
  const NetworkMemberAccept({Key? key, required this.memberId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation$AcceptNetworkMembership$Widget(
      builder: (runMutation, result) {
        return IconButton(
          key: const ValueKey("button.acceptInvitation"),
          onPressed: () {
            runMutation(
              Variables$Mutation$AcceptNetworkMembership(
                networkMemberId: memberId,
              ),
            );
          },
          icon: const Icon(Icons.check_circle),
        );
      },
    );
  }
}
