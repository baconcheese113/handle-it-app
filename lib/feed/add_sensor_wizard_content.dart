import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard_content.dart';
import 'package:handle_it/utils.dart';
import 'package:permission_handler/permission_handler.dart';

class AddSensorWizardContent extends StatefulWidget {
  final Map<String, dynamic> hub;
  const AddSensorWizardContent({Key? key, required this.hub}) : super(key: key);

  static final fragment = gql(r'''
    fragment addSensorWizardContent_hub on Hub {
      id
      name
    }
    ''');

  @override
  State<AddSensorWizardContent> createState() => _AddSensorWizardContentState();
}

class _AddSensorWizardContentState extends State<AddSensorWizardContent> {
  PageController? _formsPageViewController;
  List? _forms;
  bool _scanning = false;
  List<bool> _leftRightToggle = [true, false];
  List<bool> _frontRearToggle = [true, false];
  String? _sensorSerial;
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundHub;
  BluetoothCharacteristic? _commandChar;

  Future<void> connectToHub() async {
    if (Platform.isAndroid) {
      if (!await requestPermission(Permission.location) ||
          // !await requestPermission(Permission.bluetooth) ||
          !await requestPermission(Permission.bluetoothScan) ||
          !await requestPermission(Permission.bluetoothConnect)) {
        setState(() => _scanning = false);
        return;
      }
    }

    print("about to listen");
    if (!await tryPowerOnBLE()) {
      setState(() => _scanning = false);
      return;
    }

    print("bluetooth state is now POWERED_ON, starting peripheral scan");
    await for (final r in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
      if (r.device.name.isEmpty) continue;
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}");
      if (r.device.name == HUB_NAME) {
        _flutterBlue.stopScan();
        setState(() => _foundHub = r.device);
        break;
      }
    }
    if (_foundHub == null) {
      print("no devices found and scan stopped");
      setState(() => _scanning = false);
      return;
    }

    print(">>> connecting");
    await _foundHub!.connect();
    print(">>> connecting finished");
    if (_formsPageViewController!.page == 0) {
      print(">>>changing page");
      _formsPageViewController!.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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

    print(">>> discoveringservices");
    List<BluetoothService> services = await _foundHub!.discoverServices();

    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic commandChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(COMMAND_CHARACTERISTIC_UUID));

    String command = "StartSensorSearch:1";
    List<int> bytes = utf8.encode(command);
    print(">>> writing characteristic with value $command");
    Uint8List sensorSearchCharValue = Uint8List.fromList(bytes);
    await commandChar.write(sensorSearchCharValue);
    setState(() => _commandChar = commandChar);

    String rawSensorId = "";
    while (rawSensorId.length < 12 || rawSensorId.substring(0, 11) != "SensorFound") {
      List<int> bytes = await _commandChar!.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawSensorId = String.fromCharCodes(bytes);
      print(">>rawSensorId = $rawSensorId");
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      _scanning = false;
      _sensorSerial = rawSensorId.substring(12);
    });
    _formsPageViewController!.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
      await _commandChar?.write([]);
      await _foundHub?.disconnect();
      await _flutterBlue.stopScan();
      if (mounted) Navigator.pop(context);
      return true;
    }

    void addSensor(bool shouldExit) async {
      setState(() => _scanning = true);
      // add the sensor
      String leftOrRight = _leftRightToggle[0] ? 'Left' : 'Right';
      String frontOrRear = _frontRearToggle[0] ? 'Front' : 'Rear';
      print(">>Adding sensor id $_sensorSerial as a $leftOrRight/$frontOrRear door sensor");

      String command = "SensorConnect:1";
      List<int> bytes = utf8.encode(command);
      print(">>> writing characteristic with value $command");
      Uint8List sensorConnectCharValue = Uint8List.fromList(bytes);
      await _commandChar!.write(sensorConnectCharValue);

      String sensorAddedResponse = "";
      while (sensorAddedResponse.length < 12 || sensorAddedResponse.substring(0, 11) != "SensorAdded") {
        List<int> bytes = await _commandChar!.read();
        print(">>readCharacteristic ${bytes.toString()}");
        sensorAddedResponse = String.fromCharCodes(bytes);
        print(">>sensorAddedResponse = $sensorAddedResponse");
        await Future.delayed(const Duration(milliseconds: 500));
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
        _sensorSerial = null;
        _scanning = false;
      });
      _formsPageViewController!.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }

    _forms = [
      WillPopScope(
          onWillPop: cancelForm,
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                      Text(
                        "Scanning for ${widget.hub['name']}",
                        textScaleFactor: 1.3,
                      ),
                      const CircularProgressIndicator(),
                    ])))),
            Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: const Text("Cancel"))),
            ])
          ])),
      WillPopScope(
          onWillPop: cancelForm,
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                      Text(
                        "Turn on your sensor, then press start to search for a new sensor for ${widget.hub['name']}",
                        textScaleFactor: 1.3,
                      ),
                      _scanning
                          ? const CircularProgressIndicator()
                          : TextButton(onPressed: startSensorSearch, child: const Text("Start")),
                    ])))),
            Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: const Text("Cancel"))),
            ])
          ])),
      WillPopScope(
          onWillPop: cancelForm,
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Text("Found sensor $_sensorSerial!", textScaleFactor: 1.3),
                      const Padding(padding: EdgeInsets.only(top: 20)),
                      Text(_scanning ? "Saving, please wait..." : "Select which door this sensor is for"),
                      if (!_scanning)
                        ToggleButtons(
                          isSelected: _leftRightToggle,
                          onPressed: (idx) => setState(() => _leftRightToggle = [idx == 0, idx == 1]),
                          children: const [
                            Text("Left"),
                            Text("Right"),
                          ],
                        ),
                      if (!_scanning)
                        ToggleButtons(
                          isSelected: _frontRearToggle,
                          onPressed: (idx) => setState(() => _frontRearToggle = [idx == 0, idx == 1]),
                          children: const [
                            Text("Front"),
                            Text("Rear"),
                          ],
                        ),
                    ])))),
            Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(child: TextButton(onPressed: cancelForm, child: const Text("Cancel"))),
              // Expanded(child: TextButton(onPressed: () => addSensor(false), child: Text("Add Another"))),
              Expanded(
                  child: TextButton(onPressed: _scanning ? null : () => addSensor(true), child: const Text("Save"))),
            ])
          ])),
    ];

    return Scaffold(
      body: PageView.builder(
        controller: _formsPageViewController,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return _forms![index];
        },
      ),
    );
  }
}
