import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard_content.dart';
import 'package:handle_it/utils.dart';

class AddVehicleWizard extends StatefulWidget {
  final BleManager bleManager;
  const AddVehicleWizard({Key key, this.bleManager}) : super(key: key);

  static String routeName = "/add-vehicle";

  @override
  _AddVehicleWizardState createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: addFragments(gql(r"""
        query addVehicleWizardQuery {
          viewer {
            user {
              id
              ...addVehicleWizardContent_user
            }
          }
        }
      """), [AddVehicleWizardContent.addVehicleWizardContentFragment]),
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

        return AddVehicleWizardContent(
          bleManager: this.widget.bleManager,
          user: result.data['viewer']['user'],
        );
      },
    );
  }
}
