import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/home.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String SENSOR_VOLTS_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fc";

class AddVehicleWizard extends StatefulWidget {
  final BleManager bleManager;
  final user;
  AddVehicleWizard({this.bleManager, this.user});

  static String routeName = "/add-vehicle";

  @override
  _AddVehicleWizardState createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  final _formsPageViewController = PageController();
  List _forms;
  bool scanning = false;
  Peripheral _foundHub;
  Peripheral curDevice;

  String _hubCustomName = "";

  // TODO extract requestBLEPermissions
  // TODO extract tryPowerOnBLE
  // TODO prevent hub from connecting to sensors before wizard
  // TODO wizard for adding sensors to hub
  Future<void> findHub() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.location.status;
      print("Current status is $status");
      if (!status.isGranted) {
        print("Status was not granted");
        if (!await Permission.location.request().isGranted) {
          print("Andddd, they denied me again!");
          setState(() => scanning = false);
          return;
        }
      }
    }

    setState(() => scanning = true);
    print("about to listen");
    bool attemptedRestart = false;
    await for (BluetoothState state in this.widget.bleManager.observeBluetoothState()) {
      print(">>>>>> Observed device bluetooth state: $state");
      if (state == BluetoothState.POWERED_OFF && !attemptedRestart) {
        await this.widget.bleManager.enableRadio();
        attemptedRestart = true;
      } else if (state == BluetoothState.RESETTING) {
        attemptedRestart = false;
      } else if (state == BluetoothState.POWERED_ON) {
        break;
      }
    }
    print("bluetooth state is now POWERED_ON, starting peripheral scan");

    int scanStartSeconds = DateTime.now().second;
    await for (ScanResult scanResult in this.widget.bleManager.startPeripheralScan(scanMode: ScanMode.lowLatency)) {
      if (scanResult.peripheral.name == null) continue;
      setState(() => curDevice = scanResult.peripheral);
      print("Scanned peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
      if (scanResult.peripheral.name == HUB_NAME) {
        _foundHub = scanResult.peripheral;
        await _foundHub.connect();
        await _foundHub.discoverAllServicesAndCharacteristics();
        _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
      }
      if (_foundHub != null || DateTime.now().second > scanStartSeconds + 10) {
        await this.widget.bleManager.stopPeripheralScan();
        break;
      }
    }
    await for (PeripheralConnectionState connectionState
        in _foundHub.observeConnectionState(emitCurrentValue: true, completeOnDisconnect: true)) {
      print("Peripheral ${_foundHub.identifier} connection state is $connectionState");
      if (connectionState == PeripheralConnectionState.connected) {
        break;
      } else {
        print("Failed to connect");
        setState(() => scanning = false);
        return;
      }
    }
    print("Finished connection, just monitoring sensorValue now");
    setState(() => scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> cancelForm() async {
      if (_foundHub != null) await _foundHub.disconnectOrCancelConnection();
      Navigator.pop(context);
      return true;
    }

    return Mutation(
      options: MutationOptions(document: gql(r'''
      mutation addVehicleWizardMutation($data: HubCreateInput!) {
        createOneHub(data: $data) {
          id
        }
      }
      ''')),
      builder: (
        RunMutation runMutation,
        QueryResult result,
      ) {
        void handleAddHub() async {
          if (_formsPageViewController.page > 0) {
            await runMutation({
              'data': {
                'name': _hubCustomName,
                'serial': "testSerial", // TODO send actual serial of device
                'owner': {
                  'connect': {'id': this.widget.user['id']}
                }
              }
            }).networkResult;
            await Navigator.pushReplacementNamed(context, Home.routeName);
            return;
          }
          _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
        }

        _forms = [
          WillPopScope(
              child: Column(children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                          Text(
                            "To get started, hold the pair button on the bottom of your HandleHub for 5 seconds",
                            textScaleFactor: 1.3,
                          ),
                          if (curDevice != null) Text("...found ${curDevice.name}"),
                          scanning == true
                              ? CircularProgressIndicator()
                              : TextButton(onPressed: findHub, child: Text("Start scanning")),
                        ])))),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => cancelForm(), child: Text("Cancel"))),
                ], mainAxisSize: MainAxisSize.max)
              ]),
              onWillPop: cancelForm),
          WillPopScope(
              child: Column(children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          Text("Lets name this HandleHub", textScaleFactor: 1.3),
                          TextField(
                            decoration: InputDecoration(hintText: "Name (eg. Year/Make/Model)"),
                            onChanged: (String name) => {setState(() => _hubCustomName = name)},
                            // onSubmitted: (String s) => {_nextFormStep()},
                          )
                        ])))),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => {cancelForm()}, child: Text("Cancel"))),
                  Expanded(
                      child: TextButton(onPressed: _hubCustomName.isEmpty ? null : handleAddHub, child: Text("Add"))),
                ], mainAxisSize: MainAxisSize.max)
              ]),
              onWillPop: cancelForm),
        ];

        return Scaffold(
          body: PageView.builder(
            controller: _formsPageViewController,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return _forms[index];
            },
          ),
        );
      },
    );
  }
}
