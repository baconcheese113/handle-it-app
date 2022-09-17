import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_vehicle_wizard_content.mutation.graphql.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_wizards.fragments.graphql.dart';
import 'package:handle_it/feed/~graphql/__generated__/feed_home.query.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrouter/vrouter.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";

class AddVehicleWizardContent extends StatefulWidget {
  final Fragment$addVehicleWizardContent_user userFrag;
  final int? pairedHubId;
  final Function(int) setPairedHubId;
  final Function refetch;

  const AddVehicleWizardContent({
    Key? key,
    required this.userFrag,
    this.pairedHubId,
    required this.setPairedHubId,
    required this.refetch,
  }) : super(key: key);

  @override
  State<AddVehicleWizardContent> createState() => _AddVehicleWizardContentState();
}

class _AddVehicleWizardContentState extends State<AddVehicleWizardContent> {
  PageController? _formsPageViewController;
  List? _forms;
  bool _scanning = false;
  String _logText = "";
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundHub;
  BluetoothDevice? _curDevice;
  BluetoothCharacteristic? _commandChar;

  String _hubCustomName = "";

  @override
  void initState() {
    super.initState();
    if (widget.pairedHubId != null) {
      final hubs = widget.userFrag.hubs;
      print(">>> Looking for ${widget.pairedHubId} and Hubs are $hubs");
      _hubCustomName = hubs.firstWhere((hub) => hub.id == widget.pairedHubId).name;
    }
    print("HubCustomName is $_hubCustomName");
    _formsPageViewController = PageController(initialPage: widget.pairedHubId != null ? 1 : 0);
  }

  Future<void> _resetConn() async {
    if (_foundHub != null) await _commandChar?.write([]);
    await _foundHub?.disconnect();
    if (_scanning) await _flutterBlue.stopScan();
    setState(() {
      _logText = "";
      _scanning = false;
      _foundHub = null;
      _curDevice = null;
    });
  }

  // TODO prevent hub from connecting to sensors before wizard
  // TODO wizard for adding sensors to hub
  Future<void> _findHub() async {
    if (Platform.isAndroid) {
      if (!await requestPermission(Permission.location) ||
          // !await requestPermission(Permission.bluetooth) ||
          !await requestPermission(Permission.bluetoothScan) ||
          !await requestPermission(Permission.bluetoothConnect)) {
        setState(() => _scanning = false);
        return;
      }
    }

    if (!await tryPowerOnBLE()) {
      _resetConn();
      return;
    }

    final hubIds = widget.userFrag.hubs.map((h) => h.serial.toLowerCase()).toSet();
    print("Ignoring hubIds: $hubIds");

    setState(() => _scanning = true);
    print("bluetooth state is now POWERED_ON, starting peripheral scan");
    await for (final r in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
      if (r.device.name.isEmpty) continue;
      setState(() => _curDevice = r.device);
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}, MAC ${r.device.id.id}");
      if (r.device.name == HUB_NAME && !hubIds.contains(r.device.id.id.toLowerCase())) {
        setState(() => _foundHub = r.device);
        _flutterBlue.stopScan();
        break;
      }
    }
    if (_foundHub == null) {
      print("no new devices found and scan stopped");
      await _resetConn();
      return;
    }

    print(">>> connecting");
    await _foundHub!.connect();
    print(">>> Device fully connected");
    _flutterBlue.stopScan();
    setState(() {
      _logText += "Connected to ${_foundHub!.name}\nDiscovering services...\n";
      _scanning = false;
    });
    print(">>> discoveringservices");

    List<BluetoothService> services = await _foundHub!.discoverServices();
    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic commandChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(COMMAND_CHARACTERISTIC_UUID));
    setState(() => _logText += "Discovered all services\nClearing out transaction characteristic...\n");
    print(">>> clearing out commandChar");
    // clears out commandChar before starting, just in case we had to restart
    await commandChar.write([]);

    setState(() {
      _logText += "Cleared out characteristic\nWriting characteristic with userId...\n";
      _commandChar = commandChar;
    });

    String command = "UserId:${widget.userFrag.id}";
    List<int> bytes = utf8.encode(command);
    print(">>> writing characteristic with value $command");
    Uint8List userIdCharValue = Uint8List.fromList(bytes);
    await commandChar.write(userIdCharValue);

    setState(() => _logText += "Wrote characteristic\nListening for response...");
    print(">>Starting rawHubId parse loop");

    String rawHubId = "";
    int startTime = DateTime.now().millisecondsSinceEpoch;
    while (rawHubId.length < 6 || rawHubId.substring(0, 5) != "HubId") {
      print(">>attempting to read: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
      List<int> bytes = await commandChar.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawHubId = String.fromCharCodes(bytes);
      print(">>rawHubId = $rawHubId");
      await Future.delayed(const Duration(milliseconds: 2000));
      setState(() => _logText += ".");
      if (DateTime.now().millisecondsSinceEpoch > startTime + 60000 || _foundHub == null) {
        setState(() => _logText += "\nNever received a response, likely a network error");
        await Future.delayed(const Duration(seconds: 5));
        print(">>> Read timed out, resetting...");
        await _resetConn();
        return;
      }
    }

    print(">>Ended rawHubId parse loop");
    int hubId = int.parse(rawHubId.substring(6));
    await _resetConn();
    widget.setPairedHubId(hubId);
    print(">>Finished connection, just monitoring sensorValue now");
    await widget.refetch();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> cancelForm() async {
      _resetConn();
      context.vRouter.pop();
      return true;
    }

    return Mutation$AddVehicleWizardContent$Widget(
      options: WidgetOptions$Mutation$AddVehicleWizardContent(
        update: (cache, result) {
          if (result?.data == null) return;
          final newHub = result!.parsedData!.updateHub;
          final request = Options$Query$FeedHome().asRequest;
          final readQuery = cache.readQuery(request);
          if (readQuery == null) return;
          final map = Query$FeedHome.fromJson(readQuery);
          final hubs = map.viewer.user.hubs;
          hubs.add(Query$FeedHome$viewer$user$hubs.fromJson(newHub.toJson()));
          cache.writeQuery(request, data: map.toJson(), broadcast: true);
        },
      ),
      builder: (runMutation, result) {
        void handleSetName() async {
          if (_formsPageViewController!.page! > 0) {
            await runMutation(
              Variables$Mutation$AddVehicleWizardContent(
                id: "${widget.pairedHubId}",
                name: _hubCustomName,
              ),
            ).networkResult;
            context.vRouter.pop();
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
                          if (_scanning && _logText.isEmpty) const CircularProgressIndicator(),
                          if (!_scanning && _logText.isEmpty)
                            TextButton(onPressed: _findHub, child: const Text("Start scanning")),
                          if (_logText.isNotEmpty) Text(_logText),
                        ])))),
                Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _foundHub == null ? cancelForm : null,
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
