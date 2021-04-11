import 'package:flutter/material.dart';
import 'package:handle_it/add_vehicle_wizard.dart';

class FeedHome extends StatefulWidget {
  @override
  _FeedHomeState createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> {
  bool showAddVehicleWizard = false;

  void handleExit() {
    setState(() => showAddVehicleWizard = false);
  }

  void handleAddVehicle() {
    setState(() => showAddVehicleWizard = true);
  }

  @override
  Widget build(BuildContext context) {
    if (showAddVehicleWizard == true) {
      return AddVehicleWizard(onExit: handleExit);
    }

    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [TextButton(onPressed: this.handleAddVehicle, child: Text("Add New Vehicle"))],
    );
  }
}
