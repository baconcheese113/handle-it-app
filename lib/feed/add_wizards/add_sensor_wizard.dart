import 'package:flutter/material.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_sensor_wizard.query.graphql.dart';
import 'package:handle_it/utils.dart';

import 'add_sensor_wizard_content.dart';

class AddSensorWizard extends StatelessWidget {
  const AddSensorWizard({Key? key}) : super(key: key);

  static String routeName = "/add-sensor";

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) print("arguments: ${arguments['hubId']}");

    return Query$AddSensorWizard$Widget(
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result, allowCache: false);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;
        final hub = viewer.user.hubs.firstWhere(
          (hub) => hub.id == arguments?['hubId'],
        );

        return AddSensorWizardContent(hubFrag: hub);
      },
    );
  }
}
