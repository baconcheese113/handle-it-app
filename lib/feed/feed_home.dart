import 'package:flutter/material.dart';
import 'package:handle_it/feed/card/feed_card.dart';
import 'package:handle_it/feed/updaters/sensor_updater.dart';
import 'package:handle_it/feed/~graphql/__generated__/feed_home.query.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:version/version.dart';

class FeedHome extends StatelessWidget {
  const FeedHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Query$FeedHome$Widget(
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;
        final hubs = viewer.user.hubs;

        return RefreshIndicator(
          onRefresh: () async {
            await refetch!();
          },
          child: ListView(
            children: [
              SensorUpdater(latestVersion: Version.parse(viewer.latestSensorVersion)),
              if (hubs.isNotEmpty)
                Padding(
                  // Prevents covering Arm toggle with fab
                  padding: const EdgeInsets.only(bottom: 96),
                  child: Column(
                    children: hubs
                        .map((hub) => FeedCard(
                              hubFrag: hub,
                              onDelete: () async {
                                await refetch!();
                              },
                            ))
                        .toList(),
                  ),
                ),
              if (hubs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 192),
                    child: Text(key: ValueKey("text.emptyFeed"), "Add a hub to begin"),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
