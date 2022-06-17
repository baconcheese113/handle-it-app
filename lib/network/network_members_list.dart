import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_home.dart';
import 'package:handle_it/network/network_member_tile.dart';
import 'package:handle_it/network/network_members_create.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

class NetworkMembersList extends StatefulWidget {
  final Map<String, dynamic> networkFrag;
  final Map<String, dynamic> viewerFrag;
  const NetworkMembersList({Key? key, required this.networkFrag, required this.viewerFrag}) : super(key: key);

  static final fragment = addFragments(gql(r'''
    fragment networkMembersList_network on Network {
      id
      name
      members {
        id
        role
        user {
          isMe
        }
        ...networkMemberTile_member
      }
    }
  '''), [NetworkMemberTile.fragment]);

  @override
  State<NetworkMembersList> createState() => _NetworkMembersListState();
}

class _NetworkMembersListState extends State<NetworkMembersList> {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> network = widget.networkFrag;
    final List<dynamic> members = network['members'];
    bool isOwner = members.any((m) => m['user']['isMe'] && m['role'] == 'owner');
    final List<Widget> membersList = [];
    for (final m in members) {
      membersList.add(NetworkMemberTile(memberFrag: m));
    }
    return Mutation(
      options: MutationOptions(
        document: gql(r'''
            mutation DeleteNetwork($networkId: Int!) {
              deleteNetwork(networkId: $networkId) {
                id
              }
            }
          '''),
        update: (cache, result) {
          final request = QueryOptions(document: networkHomeQuery).asRequest;
          final map = cache.readQuery(request);
          final id = result!.data!['deleteNetwork']['id'];
          final Map<String, dynamic> viewer = map!['viewer'];
          viewer['activeNetworks']?.removeWhere((n) => n['id'] == id);
          viewer['networks']?.removeWhere((n) => n['id'] == id);
          viewer['user']?['networkMemberships']?.removeWhere((m) => m['network']['id'] == id);
          cache.writeQuery(request, data: map, broadcast: true);
        },
      ),
      builder: (RunMutation runMutation, QueryResult? result) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                children: [
                  Consumer<NetworkProvider>(
                    builder: ((context, netProvider, child) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              network['name'],
                              style: TextStyle(fontSize: 24, color: netProvider.registerNetwork(network['id'])),
                            ),
                            if (isOwner) const Chip(label: Text("Owner")),
                            if (isOwner)
                              IconButton(
                                  onPressed: () => runMutation({'networkId': network['id']}),
                                  icon: const Icon(Icons.delete)),
                          ],
                        )),
                  ),
                  Column(children: membersList),
                  NetworkMembersCreate(networkFrag: widget.networkFrag),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
