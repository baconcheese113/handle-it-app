import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_wizards.fragments.graphql.dart';
import 'package:provider/provider.dart';
import 'package:vrouter/vrouter.dart';

import '../../common/ble_provider.dart';

class AddSensorWizardContent extends StatefulWidget {
  final Fragment$addSensorWizardContent_hub hubFrag;

  const AddSensorWizardContent({Key? key, required this.hubFrag}) : super(key: key);

  @override
  State<AddSensorWizardContent> createState() => _AddSensorWizardContentState();
}

class _AddSensorWizardContentState extends State<AddSensorWizardContent> {
  PageController? _formsPageViewController;
  List? _forms;
  bool _processing = false;
  List<bool> _leftRightToggle = [true, false];
  List<bool> _frontRearToggle = [true, false];
  String? _sensorSerial;
  late BleProvider _bleProvider;
  BluetoothDevice? _foundHub;
  BluetoothCharacteristic? _commandChar;
  String _errMsg = "";

  bool frontL = true;
  bool frontR = true;
  bool rearL = true;
  bool rearR = true;

  Future<void> connectToKnownHub() async {
    if (!await _bleProvider.tryTurnOnBle()) return;

    final existingDevice = await _bleProvider.tryGetConnectedDevice(HUB_NAME);
    if (existingDevice != null) {
      setState(() => _foundHub = existingDevice);
    } else {
      await _bleProvider.scan(
          timeout: const Duration(seconds: 10),
          onScanResult: (d, iosMac) {
            final mac = (iosMac ?? d.id.id).toLowerCase();
            print("${d.name} == $HUB_NAME && $mac == ${widget.hubFrag.serial.toLowerCase()}");
            if (d.name == HUB_NAME && mac == widget.hubFrag.serial.toLowerCase()) {
              if (mounted) setState(() => _foundHub = d);
              return true;
            }
            if (d.name.isNotEmpty) print("Scanned peripheral ${d.name}, MAC $mac");
            return false;
          });
      final isConnected = await _bleProvider.tryConnect(_foundHub);
      if (!isConnected) {
        print("no hub connected and scan stopped");
        cancelForm();
        return;
      }
    }
    if (_formsPageViewController!.page == 0) {
      print(">>>changing page");
      _formsPageViewController!
          .nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void initState() {
    super.initState();
    _formsPageViewController = PageController(initialPage: 0);

    for (var sensor in widget.hubFrag.sensors) {
      if (sensor.doorRow == 0 && sensor.doorColumn == 0) frontL = false;
      if (sensor.doorRow == 0 && sensor.doorColumn == 1) frontR = false;
      if (sensor.doorRow == 1 && sensor.doorColumn == 0) rearL = false;
      if (sensor.doorRow == 1 && sensor.doorColumn == 1) rearR = false;
    }
    final canAddLeft = frontL || rearL;
    final canAddFront = canAddLeft ? frontL : frontR;
    setState(() {
      _leftRightToggle = [canAddLeft, !canAddLeft];
      _frontRearToggle = [canAddFront, !canAddFront];
    });

    // To initialize provider
    Future.delayed(const Duration(milliseconds: 1), () {
      connectToKnownHub();
    });
  }

  Future<void> startSensorSearch() async {
    if (_foundHub == null) {
      print("_foundHub is null");
      return;
    }
    setState(() => _processing = true);

    final commandChar = await _bleProvider.getChar(
      _foundHub!,
      HUB_SERVICE_UUID,
      COMMAND_CHARACTERISTIC_UUID,
    );
    if (commandChar == null) {
      print(">>> commandChar not found");
      setState(() => _processing = false);
      return;
    }

    String command = "StartSensorSearch:1";
    print(">>> writing characteristic with value $command");
    await commandChar.write(utf8.encode(command));
    setState(() => _commandChar = commandChar);

    String rawSensorId = "";
    while (rawSensorId.length < 12 || !rawSensorId.startsWith("SensorFound")) {
      List<int> bytes = await _commandChar!.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawSensorId = String.fromCharCodes(bytes);
      print(">>rawSensorId = $rawSensorId");
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      _processing = false;
      _sensorSerial = rawSensorId.substring(12);
    });
    _formsPageViewController!
        .nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<bool> cancelForm() async {
    await _foundHub?.disconnect();
    await _bleProvider.stopScan();
    if (mounted) context.vRouter.pop();
    return true;
  }

  // 1: automatically start trying to connect to hub
  // 2: Press to search for sensors (BLE message "startSensorSearch:1")
  // 3: Sensor confirm and select door (BLE messages "sensorFound:69", "sensorConnect:69" | "sensorSkip:69")
  // 4: Repeat from 2 or finish
  @override
  Widget build(BuildContext context) {
    _bleProvider = Provider.of<BleProvider>(context, listen: true);

    final isToggledLeft = _leftRightToggle[0];
    final isToggledFront = _frontRearToggle[0];

    final canAddRight = frontR || rearR;
    final canAddRear = rearL || rearR;

    final canAddLeft = frontL || rearL;
    final canAddFront = frontL || frontR;
    print('Availability is frontL $frontL frontR $frontR rearL $rearL rearR $rearR}');

    final canToggleLeftRight = isToggledLeft ? canAddRight : canAddLeft;
    final canToggleFrontRear = isToggledFront ? canAddRear : canAddFront;
    print('canToggleLeftRight $canToggleLeftRight and canToggleFrontRear $canToggleFrontRear');

    void addSensor(bool shouldExit) async {
      setState(() => _processing = true);
      // add the sensor
      String leftOrRight = _leftRightToggle[0] ? 'Left' : 'Right';
      String frontOrRear = _frontRearToggle[0] ? 'Front' : 'Rear';
      print(">>Adding sensor id $_sensorSerial as a $leftOrRight/$frontOrRear door sensor");
      final leftVal = _leftRightToggle[0] ? '0' : '1';
      final frontVal = _frontRearToggle[0] ? '0' : '1';
      String command = "SensorConnect:$leftVal$frontVal";
      print(">>> writing characteristic with value $command");
      await _commandChar!.write(utf8.encode(command));

      String sensorAddedResponse = "";
      while (sensorAddedResponse.length < 12 || !sensorAddedResponse.startsWith("SensorAdded")) {
        List<int> bytes = await _commandChar!.read();
        print(">>readCharacteristic ${bytes.toString()}");
        sensorAddedResponse = String.fromCharCodes(bytes);
        print(">>sensorAddedResponse = $sensorAddedResponse");
        await Future.delayed(const Duration(milliseconds: 500));
        if (sensorAddedResponse.startsWith("Error:")) {
          setState(() => _errMsg = sensorAddedResponse.substring(6));
          _foundHub?.disconnect();
          return;
        }
      }
      int sensorAddedResult = int.parse(sensorAddedResponse.substring(12));
      print("Sensor added result: $sensorAddedResult");

      if (shouldExit) {
        cancelForm();
        return;
      }

      setState(() {
        _leftRightToggle = [canAddLeft, !canAddLeft];
        _frontRearToggle = [canAddFront, !canAddFront];
        _sensorSerial = null;
        _processing = false;
      });
      _formsPageViewController!
          .animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }

    String sensorFoundText = (() {
      if (_errMsg.isNotEmpty) return _errMsg;
      if (_processing) return "Saving, please wait...";
      return "Select which door this sensor is for";
    }());

    _forms = [
      WillPopScope(
          onWillPop: cancelForm,
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: (Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(
                            "Scanning for ${widget.hubFrag.name}",
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
                    child: (Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(
                            "Turn on your sensor, then press start to search for a new sensor for ${widget.hubFrag.name}",
                            textScaleFactor: 1.3,
                          ),
                          _processing
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  key: const ValueKey("button.startSearch"),
                                  onPressed: startSensorSearch,
                                  child: const Text("Start"),
                                ),
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
                      Text(sensorFoundText),
                      if (!_processing)
                        ToggleButtons(
                          isSelected: _leftRightToggle,
                          onPressed: canToggleLeftRight
                              ? (idx) => setState(() {
                                    _leftRightToggle = [idx == 0, idx == 1];
                                    if (idx == 0) {
                                      _frontRearToggle = [frontL, !frontL];
                                    } else {
                                      _frontRearToggle = [frontR, !frontR];
                                    }
                                  })
                              : (idx) {},
                          children: const [
                            Text("Left"),
                            Text("Right"),
                          ],
                        ),
                      if (!_processing)
                        ToggleButtons(
                          direction: Axis.vertical,
                          isSelected: _frontRearToggle,
                          onPressed: canToggleFrontRear
                              ? (idx) => setState(() {
                                    _frontRearToggle = [idx == 0, idx == 1];
                                    if (idx == 0) {
                                      _leftRightToggle = [frontL, !frontL];
                                    } else {
                                      _leftRightToggle = [rearL, !rearL];
                                    }
                                  })
                              : (idx) {},
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
                  child: TextButton(
                      key: const ValueKey("button.save"),
                      onPressed: _processing ? null : () => addSensor(true),
                      child: const Text("Save"))),
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
