import 'package:flutter/material.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/network_invites_card.mutations.graphql.dart';

class NetworkMemberDecline extends StatelessWidget {
  final int memberId;
  const NetworkMemberDecline({Key? key, required this.memberId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation$DeclineNetworkMembership$Widget(
      builder: (runMutation, result) {
        return IconButton(
          onPressed: () {
            runMutation(
              Variables$Mutation$DeclineNetworkMembership(
                networkMemberId: memberId,
              ),
            );
          },
          icon: const Icon(Icons.clear_outlined),
        );
      },
    );
  }
}
