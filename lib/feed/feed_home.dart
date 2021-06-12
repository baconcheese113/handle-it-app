import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({Key key}) : super(key: key);
  @override
  _FeedHomeState createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> with WidgetsBindingObserver {
  // bool _showAddVehicleWizard = false;
  // List<Peripheral> _hubs = [];
  // String _hubCustomName = '';
  // BleManager _bleManager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void _handleExit([String hubCustomName, Peripheral hub]) {
  //   setState(() {
  //     // _showAddVehicleWizard = false;
  //     // if (hubCustomName != null) _hubCustomName = hubCustomName;
  //     // if (hub != null) _hubs.add(hub);
  //   });
  // }

  void _handleAddVehicle() {
    // setState(() => _showAddVehicleWizard = true);
    Navigator.pushNamed(context, AddVehicleWizard.routeName);
  }

  // void _handleDisconnect() {
  //   // setState(() => _hubs.removeLast());
  // }

  @override
  Widget build(BuildContext context) {
    // if (_showAddVehicleWizard == true) {
    //   return AddVehicleWizard(onExit: _handleExit, bleManager: _bleManager);
    // }

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
      builder: (QueryResult result, {Refetch refetch, FetchMore fetchMore}) {
        if (result.isLoading) return CircularProgressIndicator();

        final hubs = result.data.containsKey('viewer')
            ? List<Object>.from(result.data['viewer']['user']['hubs'])
            : List<Object>.from([]);
        print("hubs is $hubs");

        return RefreshIndicator(
          onRefresh: () async {
            return refetch();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (result.hasException) Text(result.exception.toString()),
                // if (result.data.containsKey('viewer')) Text(result.data['viewer'].toString()),
                TextButton(
                  onPressed: _handleAddVehicle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      Text("Add New Vehicle"),
                    ],
                  ),
                ),
                if (hubs.length > 0)
                  ...hubs
                      .map((hub) => FeedCard(
                            // hub: hub,
                            hubFrag: hub,
                            onDelete: refetch,
                            // name: "HUB_NAME", // _hubCustomName,
                            // bleManager: _bleManager,
                            // onDisconnect: _handleDisconnect,
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
