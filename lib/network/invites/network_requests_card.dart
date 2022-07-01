import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkRequestsCard extends StatelessWidget {
  final NetworkRequestsCardMemberMixin memberFrag;
  const NetworkRequestsCard({Key? key, required this.memberFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: DECLINE_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT,
        operationName: DECLINE_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
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
                DeclineNetworkMembershipArguments(
                  networkMemberId: memberFrag.id,
                ).toJson(),
              ),
              icon: const Icon(Icons.clear_outlined),
            ),
          ),
        );
      },
    );
  }
}
