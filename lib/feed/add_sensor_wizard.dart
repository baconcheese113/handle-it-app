import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_sensor_wizard_content.dart';
import 'package:handle_it/utils.dart';

class AddSensorWizard extends StatefulWidget {
  final BleManager bleManager;
  const AddSensorWizard({Key key, this.bleManager}) : super(key: key);

  static String routeName = "/add-sensor";

  @override
  _AddSensorWizardState createState() => _AddSensorWizardState();
}

class _AddSensorWizardState extends State<AddSensorWizard> {
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context).settings.arguments as Map;
    if (arguments != null) print("arguments: ${arguments['hubId']}");

    return Query(
      options: QueryOptions(
        document: addFragments(gql(r'''
        query addSensorWizardQuery {
          viewer {
            user {
              id
              hubs {
                ...addSensorWizardContent_hub
              }
            }
          }
        }
      '''), [AddSensorWizardContent.addSensorWizardContentFragment]),
      ),
      builder: (QueryResult result, {Refetch refetch, FetchMore fetchMore}) {
        if (result.hasException) {
          print("Exception ${result.exception.toString()}");
          return Text(result.exception.toString());
        }
        if (result.isLoading) return Text("Loading...");
        print(result.data['viewer']);
        if (!result.data.containsKey('viewer') || result.data['viewer']['user'] == null) {
          return null;
        }
        final hub = result.data['viewer']['user']['hubs'].firstWhere(
          (hub) => hub['id'] == arguments['hubId'],
          orElse: () => null,
        );
        if (hub == null) return null;

        return AddSensorWizardContent(
          bleManager: this.widget.bleManager,
          hub: hub,
        );
      },
    );
  }
}
