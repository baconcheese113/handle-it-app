import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_invites_tab.dart';
import 'package:handle_it/network/network_map_tab.dart';
import 'package:handle_it/network/network_members_tab.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

class NetworkHome extends StatefulWidget {
  const NetworkHome({Key? key}) : super(key: key);

  @override
  State<NetworkHome> createState() => _NetworkHomeState();
}

class _NetworkHomeState extends State<NetworkHome> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: addFragments(gql(r"""
          query networkHomeQuery {
            viewer {
              ...networkMapTab_viewer
              ...networkMembersTab_viewer
              ...networkInvitesTab_viewer
            }
          }
        """), [NetworkMapTab.fragment, NetworkMembersTab.fragment, NetworkInvitesTab.fragment])),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.data == null && result.isLoading) return const CircularProgressIndicator();
        if (result.hasException) return Center(child: Text(result.exception.toString()));

        return ChangeNotifierProvider<NetworkProvider>(
          create: (BuildContext c) => NetworkProvider(),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(tabs: [
                  Tab(key: Key("1"), text: "Map"),
                  Tab(key: Key("2"), text: "Members"),
                  Tab(key: Key("3"), text: "Invites"),
                ]),
                Expanded(
                  child: TabBarView(physics: const NeverScrollableScrollPhysics(), children: [
                    NetworkMapTab(viewerFrag: result.data!['viewer'], refetch: refetch!),
                    NetworkMembersTab(viewerFrag: result.data!['viewer'], refetch: refetch),
                    NetworkInvitesTab(viewerFrag: result.data!['viewer'], refetch: refetch),
                  ]),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
