import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handle_it/network/member/network_member_accept.dart';
import 'package:handle_it/network/member/network_member_decline.dart';
import 'package:handle_it/network/member/network_member_delete.dart';
import 'package:handle_it/network/member/network_member_update.dart';
import 'package:handle_it/network/member/~graphql/__generated__/member.fragments.graphql.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

class NetworkMemberTile extends StatefulWidget {
  final Fragment$networkMemberTile_member memberFrag;
  const NetworkMemberTile({Key? key, required this.memberFrag}) : super(key: key);

  @override
  State<NetworkMemberTile> createState() => _NetworkMemberTileState();
}

class _NetworkMemberTileState extends State<NetworkMemberTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final netProvider = Provider.of<NetworkProvider>(context, listen: false);
    final member = widget.memberFrag;
    final isMe = member.user.isMe;
    final canDelete = member.canDelete;
    final hubs = member.user.hubs;
    bool hasHubWithLocation = false;
    final List<Widget> hubListTiles = [];
    final List<Widget> hubNames = [];
    for (final hub in hubs) {
      final locs = hub.locations;
      final canViewHub = locs.isNotEmpty;
      if (canViewHub) hasHubWithLocation = true;
      hubNames.add(Text(hub.name));
      hubListTiles.add(ListTile(
        tileColor: isMe ? Colors.amberAccent : null,
        textColor: isMe ? Colors.black : null,
        iconColor: isMe ? Colors.black : null,
        title: Text(hub.name),
        subtitle: canViewHub ? const Text("Click to view on map") : null,
        dense: true,
        onTap: canViewHub
            ? () {
                DefaultTabController.of(context).animateTo(0);
                final hubLoc = LatLng(locs[0].lat, locs[0].lng);
                final selectedHub = HubObject(hub.id, member.network.id, hubLoc);
                netProvider.setSelectedHub(selectedHub);
              }
            : null,
      ));
    }
    Widget getTrailing() {
      if (member.inviterAcceptedAt == null || member.inviteeAcceptedAt == null) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          if (member.inviterAcceptedAt == null) NetworkMemberAccept(memberId: member.id),
          NetworkMemberDecline(memberId: member.id),
        ]);
      }
      return Row(mainAxisSize: MainAxisSize.min, children: [
        if (!member.user.isMe) NetworkMemberUpdate(memberFrag: member),
        NetworkMemberDelete(memberFrag: member),
      ]);
    }

    if (!hasHubWithLocation) {
      return ListTile(
        tileColor: isMe ? Colors.amberAccent : null,
        textColor: isMe ? Colors.black : null,
        iconColor: isMe ? Colors.black : null,
        leading: hasHubWithLocation ? const Icon(Icons.pin_drop) : null,
        title: Text("${member.user.email} - ${member.status.name} ${member.role.name}"),
        subtitle: Column(children: hubNames),
        trailing: canDelete ? getTrailing() : null,
      );
    }

    return ExpansionTile(
      collapsedBackgroundColor: isMe ? Colors.amberAccent : null,
      collapsedIconColor: isMe ? Colors.black : null,
      collapsedTextColor: isMe ? Colors.black : null,
      backgroundColor: isMe ? Colors.amberAccent : null,
      textColor: isMe ? Colors.black : null,
      iconColor: isMe ? Colors.black : null,
      leading: hasHubWithLocation ? const Icon(Icons.pin_drop) : null,
      title: Text("${member.user.email} - ${member.status.name} ${member.role.name}"),
      subtitle: Column(children: hubNames),
      onExpansionChanged: (isExpanded) => setState(() => _isExpanded = isExpanded),
      trailing: canDelete && _isExpanded ? getTrailing() : null,
      children: hubListTiles,
    );
  }
}
