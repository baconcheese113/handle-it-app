import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

class NetworkMembersTile extends StatefulWidget {
  final Map<String, dynamic> memberFrag;
  const NetworkMembersTile({Key? key, required this.memberFrag}) : super(key: key);

  static final fragment = gql(r'''
    fragment networkMembersTile_member on NetworkMember {
      status
      role
      network {
        id
        name
      }
      user {
        id
        isMe
        email
        hubs {
          id
          name
          locations(last: 1) {
            id
            lat
            lng
            fixedAt
          }
        }
      }
    }
  ''');

  @override
  State<NetworkMembersTile> createState() => _NetworkMembersTileState();
}

class _NetworkMembersTileState extends State<NetworkMembersTile> {
  @override
  Widget build(BuildContext context) {
    final netProvider = Provider.of<NetworkProvider>(context, listen: false);
    final Map<String, dynamic> member = widget.memberFrag;
    bool isMe = member['user']['isMe'];
    final List<dynamic> hubs = member['user']['hubs'];
    bool hasHubWithLocation = false;
    final List<Widget> hubListTiles = [];
    final List<Widget> hubNames = [];
    for (final hub in hubs) {
      final List<dynamic> locs = hub['locations'];
      final canViewHub = locs.isNotEmpty;
      if (canViewHub) hasHubWithLocation = true;
      hubNames.add(Text(hub['name']));
      hubListTiles.add(ListTile(
        tileColor: isMe ? Colors.amberAccent : null,
        textColor: isMe ? Colors.black : null,
        iconColor: isMe ? Colors.black : null,
        title: Text(hub['name']),
        subtitle: canViewHub ? const Text("Click to view on map") : null,
        dense: true,
        onTap: canViewHub
            ? () {
                DefaultTabController.of(context)!.animateTo(0);
                final hubLoc = LatLng(locs[0]['lat'], locs[0]['lng']);
                final selectedHub = HubObject(hub['id'], member['network']['id'], hubLoc);
                netProvider.setSelectedHub(selectedHub);
              }
            : null,
      ));
    }
    if (!hasHubWithLocation) {
      return ListTile(
        tileColor: isMe ? Colors.amberAccent : null,
        textColor: isMe ? Colors.black : null,
        iconColor: isMe ? Colors.black : null,
        leading: hasHubWithLocation ? const Icon(Icons.pin_drop) : null,
        title: Text("${member['user']['email']} - ${member['status']} ${member['role']}"),
        subtitle: Column(children: hubNames),
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
      title: Text("${member['user']['email']} - ${member['status']} ${member['role']}"),
      subtitle: Column(children: hubNames),
      children: hubListTiles,
    );
  }
}
