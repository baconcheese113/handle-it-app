import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/home.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String SENSOR_VOLTS_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";

class AddVehicleWizardContent extends StatefulWidget {
  final BleManager bleManager;
  final user;
  final int pairedHubId;
  final Function setPairedHubId;
  final Function refetch;

  AddVehicleWizardContent({this.user, this.bleManager, this.pairedHubId, this.setPairedHubId, this.refetch});

  static final addVehicleWizardContentFragment = gql(r"""
    fragment addVehicleWizardContent_user on User {
      id
      hubs {
        id
        name
      }
    }
  """);

  @override
  _AddVehicleWizardContentState createState() => _AddVehicleWizardContentState();
}

class _AddVehicleWizardContentState extends State<AddVehicleWizardContent> {
  PageController _formsPageViewController;
  List _forms;
  bool scanning = false;
  Peripheral _foundHub;
  Peripheral _curDevice;

  String _hubCustomName = "";

  @override
  void initState() {
    super.initState();
    if (this.widget.pairedHubId != null) {
      _hubCustomName = this.widget.user['hubs'].firstWhere(
            (hub) => hub["id"] == this.widget.pairedHubId,
            orElse: () => {"name": ""},
          )["name"];
    }
    _formsPageViewController = PageController(initialPage: this.widget.pairedHubId != null ? 1 : 0);
  }

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
      setState(() => _curDevice = scanResult.peripheral);
      print("Scanned peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
      if (scanResult.peripheral.name == HUB_NAME) {
        _foundHub = scanResult.peripheral;
        print(">>> connecting");
        await _foundHub.connect();
        print(">>> discoveringservices");
        await _foundHub.discoverAllServicesAndCharacteristics();
        String command = "UserId:${this.widget.user['id']}";
        List<int> bytes = utf8.encode(command);
        print(">>> writing characteristic with value $command");
        Uint8List userIdCharValue = Uint8List.fromList(bytes);
        await _foundHub.writeCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID, userIdCharValue, true);
      }
      if (_foundHub != null || DateTime.now().second > scanStartSeconds + 10) {
        print(">>> stopping peripheral scan");
        await this.widget.bleManager.stopPeripheralScan();
        break;
      }
    }
    await for (PeripheralConnectionState connectionState
        in _foundHub.observeConnectionState(emitCurrentValue: true, completeOnDisconnect: true)) {
      print(">>Peripheral ${_foundHub.identifier} connection state is $connectionState");
      if (connectionState == PeripheralConnectionState.connected) {
        break;
      } else {
        print("Failed to connect");
        setState(() => scanning = false);
        return;
      }
    }
    String rawHubId = "";
    while (rawHubId == null || rawHubId.length < 6 || rawHubId.substring(0, 5) != "HubId") {
      CharacteristicWithValue v = await _foundHub.readCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID);
      print(">>readCharacteristic ${v.toString()}");
      rawHubId = String.fromCharCodes(v.value);
      print(">>rawHubId = $rawHubId");
      await Future.delayed(Duration(milliseconds: 500));
    }
    int hubId = int.tryParse(rawHubId.substring(6));
    _foundHub.disconnectOrCancelConnection();
    this.widget.setPairedHubId(hubId);
    print(">>Finished connection, just monitoring sensorValue now");
    await this.widget.refetch();
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
          mutation addVehicleWizardMutation($id: ID, $name: String) {
            updateHub(id: $id, name: $name) {
              id
              name
            }
          }
        ''')),
      builder: (
        RunMutation runMutation,
        QueryResult result,
      ) {
        void handleSetName() async {
          if (_formsPageViewController.page > 0) {
            await runMutation({
              "id": this.widget.pairedHubId,
              "name": _hubCustomName,
            }).networkResult;
            await Navigator.pushReplacementNamed(context, Home.routeName);
            return;
          }
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
                          if (_curDevice != null) Text("...found ${_curDevice.name}"),
                          scanning == true
                              ? CircularProgressIndicator()
                              : TextButton(onPressed: findHub, child: Text("Start scanning")),
                        ])))),
                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _foundHub == null ? {cancelForm()} : null,
                      child: Text("Cancel"),
                    ),
                  ),
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
                          TextFormField(
                            decoration: InputDecoration(hintText: "Name (eg. Year/Make/Model)"),
                            onChanged: (String name) => {setState(() => _hubCustomName = name)},
                            initialValue: _hubCustomName,
                          )
                        ])))),
                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _hubCustomName.isEmpty ? null : handleSetName,
                      child: Text("Set Name"),
                    ),
                  ),
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
