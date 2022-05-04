import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/utils.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";

class AddVehicleWizardContent extends StatefulWidget {
  final user;
  final int pairedHubId;
  final Function setPairedHubId;
  final Function refetch;

  AddVehicleWizardContent({this.user, this.pairedHubId, this.setPairedHubId, this.refetch});

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
  bool _scanning = false;
  FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice _foundHub;
  BluetoothDevice _curDevice;
  BluetoothCharacteristic _commandChar;

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

  // TODO prevent hub from connecting to sensors before wizard
  // TODO wizard for adding sensors to hub
  Future<void> findHub() async {
    if (Platform.isAndroid) {
      if (!await requestPermission(Permission.location) ||
          // !await requestPermission(Permission.bluetooth) ||
          !await requestPermission(Permission.bluetoothScan) ||
          !await requestPermission(Permission.bluetoothConnect)) {
        setState(() => _scanning = false);
        return;
      }
    }

    setState(() => _scanning = true);
    if (!await tryPowerOnBLE()) {
      setState(() => _scanning = false);
      return;
    }

    print("bluetooth state is now POWERED_ON, starting peripheral scan");
    await for (final r in _flutterBlue.scan(timeout: Duration(seconds: 10))) {
      if (r.device.name.isEmpty) continue;
      setState(() => _curDevice = r.device);
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}");
      if (r.device.name == HUB_NAME) {
        setState(() => _foundHub = r.device);
        _flutterBlue.stopScan();
        break;
      }
    }
    if (_foundHub == null) {
      print("no devices found and scan stopped");
      setState(() => _scanning = false);
      return;
    }

    print(">>> connecting");
    await _foundHub.connect();
    print(">>> Device fully connected");
    _flutterBlue.stopScan();
    print(">>> discoveringservices");

    List<BluetoothService> services = await _foundHub.discoverServices();
    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic commandChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(COMMAND_CHARACTERISTIC_UUID));
    print(">>> clearing out commandChar");
    // clears out commandChar before starting, just in case we had to restart
    await commandChar.write([]);

    setState(() => _commandChar = commandChar);

    String command = "UserId:${this.widget.user['id']}";
    List<int> bytes = utf8.encode(command);
    print(">>> writing characteristic with value $command");
    Uint8List userIdCharValue = Uint8List.fromList(bytes);
    await commandChar.write(userIdCharValue);

    print(">>Starting rawHubId parse loop");

    String rawHubId = "";
    while (rawHubId.length < 6 || rawHubId.substring(0, 5) != "HubId") {
      print(">>attempting to read");
      List<int> bytes = await commandChar.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawHubId = String.fromCharCodes(bytes);
      print(">>rawHubId = $rawHubId");
      await Future.delayed(Duration(milliseconds: 500));
    }

    print(">>Ended rawHubId parse loop");
    int hubId = int.tryParse(rawHubId.substring(6));
    _foundHub.disconnect();
    this.widget.setPairedHubId(hubId);
    print(">>Finished connection, just monitoring sensorValue now");
    await this.widget.refetch();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> cancelForm() async {
      if (_foundHub != null) {
        if (_commandChar != null) await _commandChar.write([]);
        await _foundHub.disconnect();
      }
      _flutterBlue.stopScan();
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
                          _scanning == true
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
