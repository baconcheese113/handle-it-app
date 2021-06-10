import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";

class AddSensorWizardContent extends StatefulWidget {
  final BleManager bleManager;
  final hub;
  const AddSensorWizardContent({Key key, this.bleManager, this.hub}) : super(key: key);

  static final addSensorWizardContentFragment = gql(r'''
    fragment addSensorWizardContent_hub on Hub {
      id
      name
    }
    ''');

  @override
  _AddSensorWizardContentState createState() => _AddSensorWizardContentState();
}

class _AddSensorWizardContentState extends State<AddSensorWizardContent> {
  PageController _formsPageViewController;
  List _forms;
  bool _scanning = false;
  List<bool> _leftRightToggle = [true, false];
  List<bool> _frontRearToggle = [true, false];
  int _sensorId;
  Peripheral _foundHub;

  Future<void> connectToHub() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.location.status;
      print("Current status is $status");
      if (!status.isGranted) {
        print("Status was not granted");
        if (!await Permission.location.request().isGranted) {
          print("Andddd, they denied me again!");
          return;
        }
      }
    }
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

    int scanStartSeconds = DateTime.now().second;
    await for (ScanResult scanResult in this.widget.bleManager.startPeripheralScan(scanMode: ScanMode.lowLatency)) {
      if (scanResult.peripheral.name == null) continue;
      print("Scanned peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
      if (scanResult.peripheral.name == HUB_NAME) {
        _foundHub = scanResult.peripheral;
        print(">>> connecting");
        await _foundHub.connect();
        print(">>> discoveringservices");
        await _foundHub.discoverAllServicesAndCharacteristics();
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
        if (_formsPageViewController.page == 0) {
          _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
        break;
      } else {
        print("Failed to connect");
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    connectToHub();
    _formsPageViewController = PageController(initialPage: 0);
  }

  Future<void> startSensorSearch() async {
    if (_foundHub == null) {
      print("_foundHub is null");
      return;
    }
    setState(() => _scanning = true);

    String command = "StartSensorSearch:1";
    List<int> bytes = utf8.encode(command);
    print(">>> writing characteristic with value $command");
    Uint8List sensorSearchCharValue = Uint8List.fromList(bytes);
    await _foundHub.writeCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID, sensorSearchCharValue, true);

    String rawSensorId;
    while (rawSensorId == null || rawSensorId.length < 12 || rawSensorId.substring(0, 11) != "SensorFound") {
      CharacteristicWithValue c = await _foundHub.readCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID);
      print(">>readCharacteristic ${c.toString()}");
      rawSensorId = String.fromCharCodes(c.value);
      print(">>rawSensorId = $rawSensorId");
      await Future.delayed(Duration(milliseconds: 500));
    }
    int sensorId = int.parse(rawSensorId.substring(12));
    setState(() {
      _scanning = false;
      _sensorId = sensorId;
    });
    _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    // TODO Get slides working
    // TODO 1: automatically start trying to connect to hub
    // TODO 2: Press to search for sensors (BLE message "startSensorSearch:1")
    // TODO 3: Sensor confirm and select door (BLE messages "sensorFound:69", "sensorConnect:69" | "sensorSkip:69")
    // TODO 4: Repeat from 2 or finish
    // TODO Connect directly to specified hub (might need to save uuid from first connection)
    // TODO Fix flow in hub to not register when connecting to a previously connected phone

    Future<bool> cancelForm() async {
      if (_foundHub != null) await _foundHub.disconnectOrCancelConnection();
      Navigator.pop(context);
      return true;
    }

    void addSensor(bool shouldExit) async {
      // add the sensor
      String leftOrRight = _leftRightToggle[0] ? 'Left' : 'Right';
      String frontOrRear = _frontRearToggle[0] ? 'Front' : 'Rear';
      print(">>Adding sensor id $_sensorId as a $leftOrRight/$frontOrRear door sensor");

      String command = "SensorConnect:$_sensorId";
      List<int> bytes = utf8.encode(command);
      print(">>> writing characteristic with value $command");
      Uint8List sensorConnectCharValue = Uint8List.fromList(bytes);
      await _foundHub.writeCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID, sensorConnectCharValue, true);

      String sensorAddedResponse;
      while (sensorAddedResponse == null ||
          sensorAddedResponse.length < 12 ||
          sensorAddedResponse.substring(0, 11) != "SensorAdded") {
        CharacteristicWithValue c = await _foundHub.readCharacteristic(HUB_SERVICE_UUID, COMMAND_CHARACTERISTIC_UUID);
        print(">>readCharacteristic ${c.toString()}");
        sensorAddedResponse = String.fromCharCodes(c.value);
        print(">>sensorAddedResponse = $sensorAddedResponse");
        await Future.delayed(Duration(milliseconds: 500));
      }
      int sensorAddedResult = int.parse(sensorAddedResponse.substring(12));
      print("Sensor added result: $sensorAddedResult");

      if (shouldExit) {
        cancelForm();
        return;
      }
      setState(() {
        _leftRightToggle = [true, false];
        _frontRearToggle = [true, false];
        _sensorId = null;
      });
      _formsPageViewController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }

    _forms = [
      WillPopScope(
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                      Text(
                        "Scanning for ${this.widget.hub['name']}",
                        textScaleFactor: 1.3,
                      ),
                      CircularProgressIndicator(),
                    ])))),
            Row(children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: Text("Cancel"))),
            ], mainAxisSize: MainAxisSize.max)
          ]),
          onWillPop: cancelForm),
      WillPopScope(
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                      Text(
                        "Tap to start looking for sensors for ${this.widget.hub['name']}",
                        textScaleFactor: 1.3,
                      ),
                      _scanning
                          ? CircularProgressIndicator()
                          : TextButton(onPressed: startSensorSearch, child: Text("Start")),
                    ])))),
            Row(children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: Text("Cancel"))),
            ], mainAxisSize: MainAxisSize.max)
          ]),
          onWillPop: cancelForm),
      WillPopScope(
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Text("Found sensor $_sensorId!", textScaleFactor: 1.3),
                      Padding(padding: EdgeInsets.only(top: 20)),
                      Text("Select which door this sensor is for"),
                      ToggleButtons(
                        children: <Widget>[
                          Text("Left"),
                          Text("Right"),
                        ],
                        isSelected: _leftRightToggle,
                        onPressed: (idx) => setState(() => _leftRightToggle = [idx == 0, idx == 1]),
                      ),
                      ToggleButtons(
                        children: <Widget>[
                          Text("Front"),
                          Text("Rear"),
                        ],
                        isSelected: _frontRearToggle,
                        onPressed: (idx) => setState(() => _frontRearToggle = [idx == 0, idx == 1]),
                      ),
                    ])))),
            Row(children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: Text("Cancel"))),
              Expanded(child: TextButton(onPressed: () => addSensor(false), child: Text("Add Another"))),
              Expanded(child: TextButton(onPressed: () => addSensor(true), child: Text("Exit"))),
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
  }
}
