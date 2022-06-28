import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/utils.dart';

import 'add_vehicle_wizard_content.dart';

class AddVehicleWizard extends StatefulWidget {
  const AddVehicleWizard({Key? key}) : super(key: key);

  static String routeName = "/add-vehicle";

  @override
  State<AddVehicleWizard> createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  final _query = AddVehicleWizardQuery();
  int? _pairedHubId;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: _query.document,
        operationName: _query.operationName,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result, allowCache: false);
        if (noDataWidget != null) return noDataWidget;

        final viewer = _query.parse(result.data!).viewer;
        return AddVehicleWizardContent(
          userFrag: viewer.user,
          pairedHubId: _pairedHubId,
          setPairedHubId: (newHubId) => setState(() => _pairedHubId = newHubId),
          refetch: refetch!,
        );
      },
    );
  }
}
