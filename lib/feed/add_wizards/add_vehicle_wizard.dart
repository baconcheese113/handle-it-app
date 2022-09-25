import 'package:flutter/material.dart';
import 'package:handle_it/common/ble_provider.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_vehicle_wizard.query.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';

import 'add_vehicle_wizard_content.dart';

class AddVehicleWizard extends StatefulWidget {
  const AddVehicleWizard({Key? key}) : super(key: key);

  static const routeName = "/add-vehicle";

  @override
  State<AddVehicleWizard> createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  int? _pairedHubId;
  late BleProvider _bleProvider;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () => _bleProvider.stopScan());
  }

  @override
  Widget build(BuildContext context) {
    _bleProvider = Provider.of<BleProvider>(context);
    return Query$AddVehicleWizard$Widget(
      builder: (result, {refetch, fetchMore}) {
        final noDataWidget = validateResult(result, allowCache: false);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;
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
