import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_invites_card.dart';

import '../utils.dart';

class NetworkInvitesTab extends StatefulWidget {
  final Map<String, dynamic> viewerFrag;
  final Function refetch;
  const NetworkInvitesTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  static final fragment = addFragments(gql(r'''
    fragment networkInvitesTab_viewer on Viewer {
      user {
        id
        networkMemberships {
          ...networkInvitesCard_member
          status
          inviterAcceptedAt
          network {
            id
            name
            members {
              id
              status
            }
          }
        }
      }
    }
  '''), [NetworkInvitesCard.fragment]);
  @override
  State<NetworkInvitesTab> createState() => _NetworkInvitesTabState();
}

class _NetworkInvitesTabState extends State<NetworkInvitesTab> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> allMemberships = widget.viewerFrag['user']['networkMemberships'];
    final invitedMemberships = allMemberships.where((mem) => mem['status'] == 'invited');
    final requestedMemberships = allMemberships.where((mem) => mem['status'] == 'requested');

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
                  title: mem['network']['name'],
                );
              }).toList(),
              if (requestedMemberships.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text("No requests you've sent are pending")),
            ]),
          ]),
        ));
  }
}
