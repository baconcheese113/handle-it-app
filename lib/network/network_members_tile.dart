import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NetworkMembersTile extends StatefulWidget {
  final Map<String, dynamic> memberFrag;
  final int userId;
  const NetworkMembersTile({Key? key, required this.memberFrag, required this.userId}) : super(key: key);

  static final networkMembersTileFragment = gql(r'''
    fragment networkMembersTile_member on NetworkMember {
      status
      role
      user {
        id
        email
        hubs {
          id
          name
          locations(last: 1) {
            id
            lat
            lng
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
    final Map<String, dynamic> member = widget.memberFrag;
    bool isUser = member['user']['id'] == widget.userId;
    final List<dynamic> hubs = member['user']['hubs'];
    bool hasHubWithLocation = false;
    final List<Widget> hubListTiles = [];
    final List<Widget> hubNames = [];
    for (final hub in hubs) {
      final List<dynamic> locs = hub['locations'];
      if (locs.isNotEmpty) hasHubWithLocation = true;
      hubNames.add(Text(hub['name']));
      hubListTiles.add(ListTile(
        tileColor: isUser ? Colors.amberAccent : null,
        textColor: isUser ? Colors.black : null,
        iconColor: isUser ? Colors.black : null,
        title: Text(hub['name']),
        subtitle: const Text("Click to view on map"),
        dense: true,
        onTap: () {
          DefaultTabController.of(context)!.animateTo(0);
          // TODO Animate camera to look at specific pin for this hub
          print("Tapped");
        },
      ));
    }
    if (!hasHubWithLocation) {
      return ListTile(
        tileColor: isUser ? Colors.amberAccent : null,
        textColor: isUser ? Colors.black : null,
        iconColor: isUser ? Colors.black : null,
        leading: hasHubWithLocation ? const Icon(Icons.pin_drop) : null,
        title: Text("${member['user']['email']} - ${member['status']} ${member['role']}"),
        subtitle: Column(children: hubNames),
      );
    }

    return ExpansionTile(
      collapsedBackgroundColor: isUser ? Colors.amberAccent : null,
      collapsedIconColor: isUser ? Colors.black : null,
      collapsedTextColor: isUser ? Colors.black : null,
      backgroundColor: isUser ? Colors.amberAccent : null,
      textColor: isUser ? Colors.black : null,
      iconColor: isUser ? Colors.black : null,
      leading: hasHubWithLocation ? const Icon(Icons.pin_drop) : null,
      title: Text("${member['user']['email']} - ${member['status']} ${member['role']}"),
      subtitle: Column(children: hubNames),
      children: hubListTiles,
    );
  }
}
