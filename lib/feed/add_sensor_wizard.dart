import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_sensor_wizard_content.dart';
import 'package:handle_it/utils.dart';

class AddSensorWizard extends StatefulWidget {
  const AddSensorWizard({Key? key}) : super(key: key);

  static String routeName = "/add-sensor";

  @override
  State<AddSensorWizard> createState() => _AddSensorWizardState();
}

class _AddSensorWizardState extends State<AddSensorWizard> {
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
        final Map<String, dynamic>? hub = result.data!['viewer']['user']['hubs'].firstWhere(
          (hub) => hub['id'] == arguments?['hubId'],
          orElse: () => null,
        );
        if (hub == null) return const SizedBox();

        return AddSensorWizardContent(
          hub: hub,
        );
      },
    );
  }
}
