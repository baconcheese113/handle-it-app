import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:handle_it/feed/add_vehicle_wizard.dart';
import 'package:handle_it/feed/feed_card.dart';

class FeedHome extends StatefulWidget {
  const FeedHome({Key key}) : super(key: key);
  @override
  _FeedHomeState createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> with WidgetsBindingObserver {
  bool _showAddVehicleWizard = false;
  List<Peripheral> _hubs = [];
  String _hubCustomName = '';
  BleManager _bleManager;

  @override
  void initState() {
    super.initState();
    _bleManager = BleManager();
    _bleManager?.createClient();
  }

  @override
  void dispose() {
    _bleManager?.destroyClient();
    super.dispose();
  }

  void _handleExit([String hubCustomName, Peripheral hub]) {
    setState(() {
      _showAddVehicleWizard = false;
      if (hubCustomName != null) _hubCustomName = hubCustomName;
      if (hub != null) _hubs.add(hub);
    });
  }

  void _handleAddVehicle() {
    setState(() => _showAddVehicleWizard = true);
  }

  void _handleDisconnect() {
    setState(() => _hubs.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddVehicleWizard == true) {
      return AddVehicleWizard(onExit: _handleExit, bleManager: _bleManager);
    }

    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        ..._hubs
            .map((hub) => FeedCard(
                  hub: hub,
                  name: _hubCustomName,
                  bleManager: _bleManager,
                  onDisconnect: _handleDisconnect,
                ))
            .toList(),
      ],
    );
  }
}
