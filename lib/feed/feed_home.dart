import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({Key? key}) : super(key: key);
  @override
  State<FeedHome> createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> with WidgetsBindingObserver {
  void _handleAddVehicle() {
    Navigator.pushNamed(context, AddVehicleWizard.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: addFragments(gql(r"""
          query feedHomeQuery {
            viewer {
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
                TextButton(
                  onPressed: _handleAddVehicle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add),
                      Text("Add New Vehicle"),
                    ],
                  ),
                ),
                if (hubs.isNotEmpty)
                  ...hubs
                      .map((hub) => FeedCard(
                            hubFrag: hub,
                            onDelete: () async {
                              await refetch!();
                            },
                          ))
                      .toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
