import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/feed/card/feed_card.dart';
import 'package:handle_it/feed/updaters/sensor_updater.dart';
import 'package:handle_it/utils.dart';
import 'package:version/version.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({Key? key}) : super(key: key);
  @override
  State<FeedHome> createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> {
  final _query = FeedHomeQuery();

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
        final hubs = viewer.user.hubs;

        return RefreshIndicator(
          onRefresh: () async {
            await refetch!();
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: ListView(
              children: [
                if (result.hasException) Text(result.exception.toString()),
                SensorUpdater(latestVersion: Version.parse(result.data!['viewer']['latestSensorVersion'])),
                if (hubs.isNotEmpty)
                  ...hubs
                      .map((hub) => FeedCard(
                            hubFrag: hub,
                            onDelete: () async {
                              await refetch!();
                            },
                          ))
                      .toList(),
                if (hubs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 192),
                      child: Text("Add a hub to begin"),
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
