import 'package:flutter/material.dart';
import 'package:handle_it/graphql/__generated__/schema.graphql.dart';
import 'package:handle_it/network/invites/network_invites_card.dart';
import 'package:handle_it/network/invites/network_requests_card.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/invites.fragments.graphql.dart';

class NetworkInvitesTab extends StatelessWidget {
  final Fragment$networkInvitesTab_viewer viewerFrag;
  final Function refetch;
  const NetworkInvitesTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allMemberships = viewerFrag.user.networkMemberships;
    final invitedMemberships = allMemberships.where((mem) => mem.status == Enum$NetworkMemberStatus.invited);
    final requestedMemberships = allMemberships.where((mem) => mem.status == Enum$NetworkMemberStatus.requested);
    print('requested $requestedMemberships');

    return RefreshIndicator(
        onRefresh: () async {
          refetch();
        },
        child: ListView(
          key: const ValueKey('list.invites'),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Invitations", style: TextStyle(fontSize: 24)),
              ...invitedMemberships.map((mem) => NetworkInvitesCard(memberFrag: mem)).toList(),
              if (invitedMemberships.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text("No invites found")),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Requests to join", style: TextStyle(fontSize: 24)),
              ...requestedMemberships.map((mem) => NetworkRequestsCard(memberFrag: mem)).toList(),
              if (requestedMemberships.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text("No requests you've sent are pending")),
            ]),
          ],
        ));
  }
}
