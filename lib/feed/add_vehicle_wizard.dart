import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard_content.dart';
import 'package:handle_it/utils.dart';

class AddVehicleWizard extends StatefulWidget {
  const AddVehicleWizard({Key? key}) : super(key: key);

  static String routeName = "/add-vehicle";

  @override
  State<AddVehicleWizard> createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  int? _pairedHubId;

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
      """), [AddVehicleWizardContent.fragment]),
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          print("Exception ${result.exception.toString()}");
          return Text(result.exception.toString());
        }
        if (result.isLoading) return const Text("Loading...");
        print(result.data!['viewer']);
        if (!result.data!.containsKey('viewer') || result.data!['viewer']['user'] == null) {
          return const SizedBox();
        }

        return AddVehicleWizardContent(
          user: result.data!['viewer']['user'],
          pairedHubId: _pairedHubId,
          setPairedHubId: (newHubId) => setState(() => _pairedHubId = newHubId),
          refetch: refetch!,
        );
      },
    );
  }
}
