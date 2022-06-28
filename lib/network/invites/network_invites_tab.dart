import 'package:flutter/material.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/network/invites/network_invites_card.dart';

class NetworkInvitesTab extends StatefulWidget {
  final NetworkInvitesTabViewerMixin viewerFrag;
  final Function refetch;
  const NetworkInvitesTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  @override
  State<NetworkInvitesTab> createState() => _NetworkInvitesTabState();
}

class _NetworkInvitesTabState extends State<NetworkInvitesTab> {
  @override
  Widget build(BuildContext context) {
    final allMemberships = widget.viewerFrag.user.networkMemberships;
    final invitedMemberships = allMemberships.where((mem) => mem.status == NetworkMemberStatus.invited);
    final requestedMemberships = allMemberships.where((mem) => mem.status == NetworkMemberStatus.requested);
    print('requested $requestedMemberships');

    return RefreshIndicator(
        onRefresh: () async {
          widget.refetch();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Invitations", style: TextStyle(fontSize: 24)),
              ...invitedMemberships.map((mem) => NetworkInvitesCard(memberFrag: mem)).toList(),
              if (invitedMemberships.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text("No invites found")),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Requests to join", style: TextStyle(fontSize: 24)),
              ...requestedMemberships.map((mem) {
                return ListTile(
                  title: Text(mem.memNetwork.name),
                );
              }).toList(),
              if (requestedMemberships.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text("No requests you've sent are pending")),
            ]),
          ]),
        ));
  }
}
