import 'package:flutter/material.dart';
import 'package:handle_it/graphql/__generated__/schema.graphql.dart';
import 'package:handle_it/network/invites/~graphql/__generated__/invites.fragments.graphql.dart';
import 'package:handle_it/network/member/network_member_accept.dart';
import 'package:handle_it/network/member/network_member_decline.dart';
import 'package:handle_it/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkInvitesCard extends StatelessWidget {
  final Fragment$networkInvitesCard_member memberFrag;
  const NetworkInvitesCard({Key? key, required this.memberFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inviterAcceptedAt = memberFrag.inviterAcceptedAt;
    if (inviterAcceptedAt == null) return const SizedBox();
    final invitationCreatedAt = timeago.format(inviterAcceptedAt);
    final network = memberFrag.network;
    final members = network.members;
    final int numMembers = members
        .where(
          (mem) => mem.status == Enum$NetworkMemberStatus.active,
        )
        .length;
    return Card(
      child: ListTile(
        title: Text(network.name),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Invited $invitationCreatedAt"),
          Text(pluralize("active member", numMembers)),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          NetworkMemberAccept(memberId: memberFrag.id),
          NetworkMemberDecline(memberId: memberFrag.id),
        ]),
      ),
    );
  }
}
