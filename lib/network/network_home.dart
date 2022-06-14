import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_map_tab.dart';
import 'package:handle_it/network/network_members_tab.dart';
import 'package:handle_it/utils.dart';

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
            }
          }
        """), [NetworkMapTab.networkMapTabFragment, NetworkMembersTab.networkMembersTabFragment])),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const CircularProgressIndicator();
        if (result.hasException) return const Center(child: Text("Failed to load"));

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [
                Tab(key: Key("1"), text: "Map"),
                Tab(key: Key("2"), text: "Members"),
              ]),
              Expanded(
                child: TabBarView(physics: const NeverScrollableScrollPhysics(), children: [
                  NetworkMapTab(viewerFrag: result.data!['viewer'], refetch: refetch!),
                  NetworkMembersTab(viewerFrag: result.data!['viewer'], refetch: refetch),
                ]),
              )
            ],
          ),
        );
      },
    );
  }
}
