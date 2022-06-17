import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkInvitesCard extends StatefulWidget {
  final Map<String, dynamic> memberFrag;
  const NetworkInvitesCard({Key? key, required this.memberFrag}) : super(key: key);

  static final fragment = gql(r'''
    fragment networkInvitesCard_member on NetworkMember {
      id
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
  ''');
  @override
  State<NetworkInvitesCard> createState() => _NetworkInvitesCardState();
}

class _NetworkInvitesCardState extends State<NetworkInvitesCard> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(document: gql(r'''
      mutation DeclineNetworkMembership($networkMemberId: Int!) {
        declineNetworkMembership(networkMemberId: $networkMemberId) {
          id
          networkMemberships {
            id
            status
          }
        }
      }
    ''')),
      builder: (RunMutation runDeclineMutation, QueryResult? result) {
        return Mutation(
          options: MutationOptions(document: gql(r'''
            mutation AcceptNetworkMembership($networkMemberId: Int!) {
              acceptNetworkMembership(networkMemberId: $networkMemberId) {
                id
                userId
                status
              }
            }
          ''')),
          builder: (RunMutation runAcceptMutation, QueryResult? result) {
            final invitationCreatedAt = timeago.format(DateTime.parse(widget.memberFrag['inviterAcceptedAt']));
            final Map<String, dynamic> network = widget.memberFrag['network'];
            final List<dynamic> members = network['members'];
            final int numMembers = members.where((mem) => mem['status'] == 'active').length;
            return Card(
              child: ListTile(
                title: Text(network['name']),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Invited $invitationCreatedAt"),
                  Text(pluralize("active member", numMembers)),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    onPressed: () => runAcceptMutation({'networkMemberId': widget.memberFrag['id']}),
                    icon: const Icon(Icons.check_circle),
                  ),
                  IconButton(
                    onPressed: () => runDeclineMutation({'networkMemberId': widget.memberFrag['id']}),
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
