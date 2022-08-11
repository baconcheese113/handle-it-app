import 'package:flutter/material.dart';
import 'package:handle_it/network/members/network_members_create.dart';
import 'package:handle_it/network/members/~graphql/__generated__/members.fragments.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_list.mutation.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_tab.query.graphql.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

import '../member/network_member_tile.dart';

class NetworkMembersList extends StatefulWidget {
  final Fragment$networkMembersList_network networkFrag;
  const NetworkMembersList({Key? key, required this.networkFrag}) : super(key: key);

  @override
  State<NetworkMembersList> createState() => _NetworkMembersListState();
}

class _NetworkMembersListState extends State<NetworkMembersList> {
  @override
  Widget build(BuildContext context) {
    final networkFrag = widget.networkFrag;
    final members = networkFrag.members;
    var isOwner = members.any((m) => m.user.isMe && m.role.name == 'owner');
    final List<Widget> membersList = [];
    for (final m in members) {
      membersList.add(NetworkMemberTile(memberFrag: m));
    }
    return Mutation$DeleteNetwork$Widget(
      options: WidgetOptions$Mutation$DeleteNetwork(
        update: (cache, result) {
          if (result?.data == null) return;
          final networkId = result!.parsedData!.deleteNetwork.id;
          final request = Options$Query$NetworkMembersTab().asRequest;
          final readQuery = cache.readQuery(request);
          if (readQuery == null) return;
          final map = Query$NetworkMembersTab.fromJson(readQuery);
          map.viewer.networks.removeWhere((n) => n.id == networkId);
          cache.writeQuery(request, data: map.toJson(), broadcast: true);
        },
      ),
      builder: (runMutation, result) {
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
                              networkFrag.name,
                              style: TextStyle(fontSize: 24, color: netProvider.registerNetwork(networkFrag.id)),
                            ),
                            if (isOwner) const Chip(label: Text("Owner")),
                            if (isOwner)
                              IconButton(
                                  key: const ValueKey('button.deleteNetwork'),
                                  onPressed: () => runMutation(
                                        Variables$Mutation$DeleteNetwork(
                                          networkId: networkFrag.id,
                                        ),
                                      ),
                                  icon: const Icon(Icons.delete)),
                          ],
                        )),
                  ),
                  Column(children: membersList),
                  NetworkMembersCreate(networkFrag: networkFrag),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
