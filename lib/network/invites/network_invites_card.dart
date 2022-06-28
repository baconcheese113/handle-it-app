import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkInvitesCard extends StatefulWidget {
  final NetworkInvitesCardMemberMixin memberFrag;
  const NetworkInvitesCard({Key? key, required this.memberFrag}) : super(key: key);

  @override
  State<NetworkInvitesCard> createState() => _NetworkInvitesCardState();
}

class _NetworkInvitesCardState extends State<NetworkInvitesCard> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: DECLINE_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT,
        operationName: DECLINE_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runDeclineMutation, result) {
        return Mutation(
          options: MutationOptions(
            document: ACCEPT_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT,
            operationName: ACCEPT_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT_OPERATION_NAME,
          ),
          builder: (runAcceptMutation, result) {
            final inviterAcceptedAt = widget.memberFrag.inviterAcceptedAt;
            if (inviterAcceptedAt == null) return const SizedBox();
            final invitationCreatedAt = timeago.format(inviterAcceptedAt);
            final network = widget.memberFrag.memberNetwork;
            final members = network.members;
            final int numMembers = members.where((mem) => mem.status == NetworkMemberStatus.active).length;
            return Card(
              child: ListTile(
                title: Text(network.name),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Invited $invitationCreatedAt"),
                  Text(pluralize("active member", numMembers)),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    onPressed: () => runAcceptMutation({'networkMemberId': widget.memberFrag.id}),
                    icon: const Icon(Icons.check_circle),
                  ),
                  IconButton(
                    onPressed: () => runDeclineMutation({'networkMemberId': widget.memberFrag.id}),
                    icon: const Icon(Icons.clear_outlined),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
