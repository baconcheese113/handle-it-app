import 'package:flutter/material.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/network/~graphql/__generated__/network_home.query.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

import 'invites/network_invites_tab.dart';
import 'map/network_map_tab.dart';
import 'members/network_members_tab.dart';

class NetworkHome extends StatelessWidget {
  const NetworkHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Query$NetworkHome$Widget(
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;

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
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      NetworkMapTab(viewerFrag: viewer, refetch: refetch!),
                      const NetworkMembersTab(),
                      NetworkInvitesTab(viewerFrag: viewer, refetch: refetch),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
