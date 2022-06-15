import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_members_create.dart';
import 'package:handle_it/network/network_members_tile.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

class NetworkMembersList extends StatefulWidget {
  final Map<String, dynamic> networkFrag;
  final Map<String, dynamic> viewerFrag;
  const NetworkMembersList({Key? key, required this.networkFrag, required this.viewerFrag}) : super(key: key);

  static final networkMembersListFragment = addFragments(gql(r'''
    fragment networkMembersList_network on Network {
      id
      name
      members {
        id
        role
        userId
        ...networkMembersTile_member
      }
    }
    fragment networkMembersList_viewer on Viewer {
      user {
        id
      }
    }
  '''), [NetworkMembersTile.networkMembersTileFragment]);

  @override
  State<NetworkMembersList> createState() => _NetworkMembersListState();
}

class _NetworkMembersListState extends State<NetworkMembersList> {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> network = widget.networkFrag;
    final List<dynamic> members = network['members'];
    final int userId = widget.viewerFrag['user']['id'];
    bool isOwner = false;
    final List<Widget> membersList = [];
    for (final m in members) {
      if (m['userId'] == userId && m['role'] == 'owner') isOwner = true;
      membersList.add(NetworkMembersTile(memberFrag: m, userId: userId));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Consumer<NetworkProvider>(
            builder: ((context, netProvider, child) => Row(
                  children: [
                    Text(network['name'],
                        style: TextStyle(fontSize: 24, color: netProvider.getColorForId(network['id']))),
                    // TODO if (isOwner) IconButton(onPressed: handleAddMember, icon: const Icon(Icons.add))
                  ],
                )),
          ),
        ),
        Column(children: membersList),
        NetworkMembersCreate(networkFrag: widget.networkFrag),
      ],
    );
  }
}
