import 'package:flutter/material.dart';
import 'package:handle_it/network/members/network_create.dart';
import 'package:handle_it/network/members/network_members_join.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_tab.query.graphql.dart';
import 'package:handle_it/utils.dart';

import 'network_members_list.dart';

class NetworkMembersTab extends StatelessWidget {
  const NetworkMembersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Query$NetworkMembersTab$Widget(
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;
        final networksList = [];
        for (final n in viewer.networks) {
          networksList.add(NetworkMembersList(networkFrag: n));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await refetch!();
          },
          child: ListView(key: const ValueKey('list.networks'), children: [
            const NetworkCreate(),
            const NetworkMembersJoin(),
            ...networksList.reversed.toList(),
          ]),
        );
      },
    );
  }
}
