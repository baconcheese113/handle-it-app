import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/network/members/network_create.dart';
import 'package:handle_it/network/members/network_members_join.dart';
import 'package:handle_it/utils.dart';

import 'network_members_list.dart';

class NetworkMembersTab extends StatefulWidget {
  const NetworkMembersTab({Key? key}) : super(key: key);

  @override
  State<NetworkMembersTab> createState() => _NetworkMembersTabState();
}

class _NetworkMembersTabState extends State<NetworkMembersTab> {
  final _query = NetworkMembersTabQuery();
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
