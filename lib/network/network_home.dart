import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

import 'invites/network_invites_tab.dart';
import 'map/network_map_tab.dart';
import 'members/network_members_tab.dart';

class NetworkHome extends StatefulWidget {
  const NetworkHome({Key? key}) : super(key: key);

  @override
  State<NetworkHome> createState() => _NetworkHomeState();
}

class _NetworkHomeState extends State<NetworkHome> {
  final _query = NetworkHomeQuery();

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: _query.document,
        operationName: _query.operationName,
      ),
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final viewer = _query.parse(result.data!).viewer;

        return ChangeNotifierProvider<NetworkProvider>(
          create: (BuildContext c) => NetworkProvider(),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(tabs: [
                  Tab(key: ValueKey('tab.map'), text: "Map"),
                  Tab(key: ValueKey("tab.members"), text: "Members"),
                  Tab(key: ValueKey("tab.invites"), text: "Invites"),
                ]),
                Expanded(
                  child: TabBarView(physics: const NeverScrollableScrollPhysics(), children: [
                    NetworkMapTab(viewerFrag: viewer, refetch: refetch!),
                    const NetworkMembersTab(),
                    NetworkInvitesTab(viewerFrag: viewer, refetch: refetch),
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
