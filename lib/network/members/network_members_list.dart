import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/network/members/network_members_create.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

import '../member/network_member_tile.dart';

class NetworkMembersList extends StatefulWidget {
  final NetworkMembersListNetworkMixin networkFrag;
  const NetworkMembersList({Key? key, required this.networkFrag}) : super(key: key);

  @override
  State<NetworkMembersList> createState() => _NetworkMembersListState();
}

class _NetworkMembersListState extends State<NetworkMembersList> {
  @override
  Widget build(BuildContext context) {
    print(">>> runtimeType is ${widget.networkFrag.runtimeType}");
    final networkFrag = widget.networkFrag;
    final members = networkFrag.networkMembers;
    var isOwner = members.any((m) => m.user.isMe && m.role.name == 'owner');
    final List<Widget> membersList = [];
    for (final m in members) {
      membersList.add(NetworkMemberTile(memberFrag: m));
    }
    return Mutation(
      options: MutationOptions(
        document: DELETE_NETWORK_MUTATION_DOCUMENT,
        operationName: DELETE_NETWORK_MUTATION_DOCUMENT_OPERATION_NAME,
        update: (cache, result) {
          final data = result?.data;
          if (data == null) return;
          final id = data['deleteNetwork']['id'];
          final query = NetworkHomeQuery();
          final request = QueryOptions(document: query.document).asRequest;
          final map = query.parse(cache.readQuery(request)!);
          final viewer = map.viewer;
          viewer.activeNetworks.removeWhere((n) => n.id == id);
          viewer.networks.removeWhere((n) => n.id == id);
          viewer.user.networkMemberships.removeWhere((m) => m.memNetwork.id == id);
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
                                  onPressed: () => runMutation(
                                        DeleteNetworkArguments(
                                          networkId: networkFrag.id,
                                        ).toJson(),
                                      ),
                                  icon: const Icon(Icons.delete)),
                          ],
                        )),
                  ),
                  Column(children: membersList),
                  NetworkMembersCreate(networkFrag: networkFrag as NetworkMembersCreateNetworkMixin),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
