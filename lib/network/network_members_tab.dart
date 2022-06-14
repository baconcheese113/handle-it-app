import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_members_list.dart';
import 'package:handle_it/utils.dart';

class NetworkMembersTab extends StatefulWidget {
  final Map<String, dynamic> viewerFrag;
  final Function refetch;
  const NetworkMembersTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  static final networkMembersTabFragment = addFragments(gql(r'''
    fragment networkMembersTab_viewer on Viewer {
      ...networkMembersList_viewer
      networks {
        ...networkMembersList_network
      }
    }
  '''), [NetworkMembersList.networkMembersListFragment]);
  @override
  State<NetworkMembersTab> createState() => _NetworkMembersTabState();
}

class _NetworkMembersTabState extends State<NetworkMembersTab> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> networks = widget.viewerFrag['networks'];
    final List<Widget> networksList = [];
    for (final n in networks) {
      networksList.add(NetworkMembersList(networkFrag: n, viewerFrag: widget.viewerFrag));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await widget.refetch();
      },
      child: Mutation(
        options: MutationOptions(document: gql(r'''
          mutation CreateNetwork($name: String!) {
            createNetwork(name: $name) {
              id
              name
              members {
                userId
                role
              }
              createdById
              createdAt
            }
          }
        ''')),
        builder: (RunMutation runMutation, QueryResult? result) {
          void handleCreateNetwork() {
            String name = "";
            showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text("Enter Network Name"),
                  content: TextFormField(onChanged: (String n) => name = n),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                    TextButton(
                        onPressed: () async {
                          await runMutation({'name': name}).networkResult;
                          if (mounted) Navigator.of(dialogContext).pop();
                        },
                        child: const Text("Create"))
                  ],
                );
              },
            );
          }

          return SingleChildScrollView(
            child: Column(children: [
              TextButton(onPressed: handleCreateNetwork, child: const Text("Create Network")),
              ...networksList.reversed.toList(),
            ]),
          );
        },
      ),
    );
  }
}
