import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/utils.dart';

import 'add_sensor_wizard_content.dart';

class AddSensorWizard extends StatefulWidget {
  const AddSensorWizard({Key? key}) : super(key: key);

  static String routeName = "/add-sensor";

  @override
  State<AddSensorWizard> createState() => _AddSensorWizardState();
}

class _AddSensorWizardState extends State<AddSensorWizard> {
  final _query = AddSensorWizardQuery();
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) print("arguments: ${arguments['hubId']}");

    return Query(
      options: QueryOptions(
        document: _query.document,
        operationName: _query.operationName,
        fetchPolicy: FetchPolicy.noCache,
      ),
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result, allowCache: false);
        if (noDataWidget != null) return noDataWidget;

        final viewer = _query.parse(result.data!).viewer;
        final hub = viewer.user.hubs.firstWhere(
          (hub) => hub.id == arguments?['hubId'],
        );

        return AddSensorWizardContent(hubFrag: hub);
      },
    );
  }
}
