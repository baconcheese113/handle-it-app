import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> connectToHub() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.location.status;
      print("Current status is $status");
      if (!status.isGranted) {
        print("Status was not granted");
        if (!await Permission.location.request().isGranted) {
          print("Andddd, they denied me again!");
          setState(() => _scanning = false);
          return;
        }
      }
    }
    await Future.delayed(Duration(seconds: 3));
    print("page is ${_formsPageViewController.page}");
    if (_formsPageViewController.page == 0) {
      _formsPageViewController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void initState() {
    super.initState();
    connectToHub();
    _formsPageViewController = PageController(initialPage: 0);
  }

  Future<void> startSensorSearch() async {
    setState(() => _scanning = true);
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      _scanning = false;
      _sensorId = 69;
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
      Navigator.pop(context);
      return true;
    }

    void addSensor() {
      // add the sensor
      String leftOrRight = _leftRightToggle[0] ? 'Left' : 'Right';
      String frontOrRear = _frontRearToggle[0] ? 'Front' : 'Rear';
      print(">>Adding sensor id $_sensorId as a $leftOrRight/$frontOrRear door sensor");
      Navigator.pop(context);
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
              Expanded(
                child: TextButton(onPressed: () => cancelForm(), child: Text("Cancel")),
              ),
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
              Expanded(
                child: TextButton(onPressed: () => cancelForm(), child: Text("Cancel")),
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
              Expanded(
                child: TextButton(onPressed: cancelForm, child: Text("Cancel")),
              ),
              Expanded(
                child: TextButton(onPressed: addSensor, child: Text("Connect")),
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
  }
}
