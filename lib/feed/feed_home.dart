import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/feed/sensor_updater.dart';
import 'package:handle_it/utils.dart';
import 'package:version/version.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({Key? key}) : super(key: key);
  @override
  State<FeedHome> createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: addFragments(gql(r"""
          query feedHomeQuery {
            viewer {
              latestSensorVersion
              user {
                id
                hubs {
                  ...feedCard_hub
                }
              }
            }
          }
        """), [FeedCard.feedCardFragment]),
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const CircularProgressIndicator();

        final hubs = result.data!.containsKey('viewer')
            ? List<dynamic>.from(result.data!['viewer']['user']['hubs'])
            : List<dynamic>.from([]);
        print("hubs is $hubs");

        return RefreshIndicator(
          onRefresh: () async {
            await refetch!();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
