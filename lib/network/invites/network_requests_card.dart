import 'package:flutter/material.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/invites.fragments.graphql.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/network_invites_card.mutations.graphql.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkRequestsCard extends StatelessWidget {
  final Fragment$networkRequestsCard_member memberFrag;
  const NetworkRequestsCard({Key? key, required this.memberFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation$DeclineNetworkMembership$Widget(
      builder: (runMutation, result) {
        final inviteeAcceptedAt = memberFrag.inviteeAcceptedAt;
        if (inviteeAcceptedAt == null) return const SizedBox();
        final invitationCreatedAt = timeago.format(inviteeAcceptedAt);
        return Card(
          child: ListTile(
            title: Text(memberFrag.network.name),
            subtitle: Text("Sent $invitationCreatedAt"),
            trailing: IconButton(
              onPressed: () => runMutation(
                Variables$Mutation$DeclineNetworkMembership(
                  networkMemberId: memberFrag.id,
                ),
              ),
              icon: const Icon(Icons.clear_outlined),
            ),
          ),
        );
      },
    );
  }
}
