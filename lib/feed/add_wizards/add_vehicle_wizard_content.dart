import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/utils.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";

class AddVehicleWizardContent extends StatefulWidget {
  final Map<String, dynamic> user;
  final int? pairedHubId;
  final Function(int) setPairedHubId;
  final Function refetch;

  const AddVehicleWizardContent({
    Key? key,
    required this.user,
    this.pairedHubId,
    required this.setPairedHubId,
    required this.refetch,
  }) : super(key: key);

  static final fragment = gql(r"""
    fragment addVehicleWizardContent_user on User {
      id
      hubs {
        id
        name
      }
    }
  """);

  @override
  State<AddVehicleWizardContent> createState() => _AddVehicleWizardContentState();
}

class _AddVehicleWizardContentState extends State<AddVehicleWizardContent> {
  PageController? _formsPageViewController;
  List? _forms;
  bool _scanning = false;
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundHub;
  BluetoothDevice? _curDevice;
  BluetoothCharacteristic? _commandChar;

  String _hubCustomName = "";

  @override
  void initState() {
    super.initState();
    if (widget.pairedHubId != null) {
      _hubCustomName = widget.user['hubs'].firstWhere(
        (hub) => hub["id"] == widget.pairedHubId,
        orElse: () => {"name": ""},
      )["name"];
    }
    _formsPageViewController = PageController(initialPage: widget.pairedHubId != null ? 1 : 0);
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
    await for (final r in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
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

    late BluetoothDeviceState deviceState;
    final stateStreamSub = _foundHub!.state.listen((state) {
      deviceState = state;
      print(">>> New state: $state");
    });

    print(">>> connecting");
    await _foundHub!.connect();
    print(">>> Device fully connected");
    _flutterBlue.stopScan();
    print(">>> discoveringservices");

    List<BluetoothService> services = await _foundHub!.discoverServices();
    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic commandChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(COMMAND_CHARACTERISTIC_UUID));
    print(">>> clearing out commandChar");
    // clears out commandChar before starting, just in case we had to restart
    await commandChar.write([]);

    setState(() => _commandChar = commandChar);

    String command = "UserId:${widget.user['id']}";
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
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print(">>Ended rawHubId parse loop");
    int hubId = int.parse(rawHubId.substring(6));
    _foundHub!.disconnect();
    stateStreamSub.cancel();
    widget.setPairedHubId(hubId);
    print(">>Finished connection, just monitoring sensorValue now");
    await widget.refetch();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> cancelForm() async {
      await _foundHub?.disconnect();
      await _commandChar?.write([]);
      _flutterBlue.stopScan();
      if (!mounted) return true;
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
        QueryResult? result,
      ) {
        void handleSetName() async {
          if (_formsPageViewController!.page! > 0) {
            await runMutation({
              "id": widget.pairedHubId,
              "name": _hubCustomName,
            }).networkResult;
            if (!mounted) return;
            Navigator.pop(context);
          }
        }

        _forms = [
          WillPopScope(
              onWillPop: cancelForm,
              child: Column(children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                          const Text(
                            "To get started, hold the pair button on the bottom of your HandleHub for 5 seconds",
                            textScaleFactor: 1.3,
                          ),
                          if (_curDevice != null) Text("...found ${_curDevice!.name}"),
                          _scanning == true
                              ? const CircularProgressIndicator()
                              : TextButton(onPressed: findHub, child: const Text("Start scanning")),
                        ])))),
                Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _foundHub == null ? {cancelForm()} : null,
                      child: const Text("Cancel"),
                    ),
                  ),
                ])
              ])),
          WillPopScope(
              onWillPop: cancelForm,
              child: Column(children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: (Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          const Text("Lets name this HandleHub", textScaleFactor: 1.3),
                          TextFormField(
                            decoration: const InputDecoration(hintText: "Name (eg. Year/Make/Model)"),
                            onChanged: (String name) => {setState(() => _hubCustomName = name)},
                            initialValue: _hubCustomName,
                          )
                        ])))),
                Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _hubCustomName.isEmpty ? null : handleSetName,
                      child: const Text("Set Name"),
                    ),
                  ),
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
      },
    );
  }
}
