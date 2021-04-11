import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";

class AddVehicleWizard extends StatefulWidget {
  final Function onExit;
  AddVehicleWizard({this.onExit});

  @override
  _AddVehicleWizardState createState() => _AddVehicleWizardState();
}

class _AddVehicleWizardState extends State<AddVehicleWizard> {
  final _formsPageViewController = PageController();
  List _forms;
  bool scanning = false;
  BleManager bleManager;
  Peripheral hub;
  Peripheral curDevice;

  String hubCustomName = "";

  @override
  void initState() {
    super.initState();
    print("initState");
    bleManager = BleManager();
    bleManager.createClient();
  }

  @override
  void dispose() {
    super.dispose();
    bleManager.destroyClient();
  }

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
    await for (BluetoothState state in bleManager.observeBluetoothState()) {
      print(">>>>>> HOLA PAPI $state");
      if (state == BluetoothState.POWERED_OFF && !attemptedRestart) {
        await bleManager.enableRadio();
        attemptedRestart = true;
      } else if (state == BluetoothState.RESETTING) {
        attemptedRestart = false;
      } else if (state == BluetoothState.POWERED_ON) {
        break;
      }
    }
    print("out of listen");
    setState(() => scanning = false);

    int scanStartSeconds = DateTime.now().second;
    await for (ScanResult scanResult in bleManager.startPeripheralScan(scanMode: ScanMode.lowLatency)) {
      if (scanResult.peripheral.name == null) continue;
      setState(() => curDevice = scanResult.peripheral);
      print("Scanned peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
      if (scanResult.peripheral.name == HUB_NAME) {
        hub = scanResult.peripheral;
        await hub.connect();
        this._nextFormStep();
      }
      if (hub != null || DateTime.now().second > scanStartSeconds + 10) {
        await bleManager.stopPeripheralScan();
        break;
      }
    }
    print("Finished");
    setState(() => scanning = false);
  }

  void _nextFormStep() {
    if (_formsPageViewController.page > 1) {
      widget.onExit();
      return;
    }
    _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> cancelForm() async {
      if (hub != null) await hub.disconnectOrCancelConnection();
      widget.onExit();
      return true;
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
              Expanded(child: TextButton(onPressed: () => {cancelForm()}, child: Text("Cancel"))),
              // Expanded(child: TextButton(onPressed: () => {_nextFormStep()}, child: Text("Next"))),
            ], mainAxisSize: MainAxisSize.max)
          ]),
          onWillPop: () async => await cancelForm()),
      WillPopScope(
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      Text(
                        "Lets name this HandleHub",
                        textScaleFactor: 1.3,
                      ),
                      TextField(
                        decoration: InputDecoration(hintText: "Name (eg. Year/Make/Model)"),
                        onChanged: (String name) => {setState(() => hubCustomName = name)},
                        onSubmitted: (String s) => {_nextFormStep()},
                      )
                    ])))),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => {cancelForm()}, child: Text("Cancel"))),
              Expanded(child: TextButton(onPressed: hubCustomName.isEmpty ? null : _nextFormStep, child: Text("Add"))),
            ], mainAxisSize: MainAxisSize.max)
          ]),
          onWillPop: () async => await cancelForm()),
    ];

    return PageView.builder(
        controller: _formsPageViewController,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return _forms[index];
        });
  }
}
