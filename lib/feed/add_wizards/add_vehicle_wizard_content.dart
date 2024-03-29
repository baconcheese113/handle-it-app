import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_vehicle_wizard_content.mutation.graphql.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_wizards.fragments.graphql.dart';
import 'package:provider/provider.dart';
import 'package:vrouter/vrouter.dart';

import '../../common/ble_provider.dart';

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
  String _logText = "";
  BluetoothDevice? _foundHub;
  BluetoothDevice? _curDevice;
  late BleProvider _bleProvider;
  String _errMsg = "";
  String _hubCustomName = "";

  void setFormPage() {
    if (widget.pairedHubId != null) {
      final hubs = widget.userFrag.hubs;
      print(">>> Looking for ${widget.pairedHubId} and Hubs are ${hubs.map((h) => h.id)}");
      _hubCustomName = hubs.firstWhere((hub) => hub.id == widget.pairedHubId).name;
      print("HubCustomName is $_hubCustomName");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formsPageViewController!.hasClients) {
          _formsPageViewController?.animateToPage(
            1,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _formsPageViewController = PageController(initialPage: widget.pairedHubId != null ? 1 : 0);
    setFormPage();
  }

  @override
  void didUpdateWidget(covariant AddVehicleWizardContent oldWidget) {
    setFormPage();
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _resetConn() async {
    await _foundHub?.disconnect();
    if (_bleProvider.scanning) await _bleProvider.stopScan();
    setState(() {
      _logText = "";
      _foundHub = null;
      _curDevice = null;
      _errMsg = "";
    });
  }

  Future<void> _findNewHub() async {
    if (!await _bleProvider.tryTurnOnBle()) return _resetConn();

    final hubIds = widget.userFrag.hubs.map((h) => h.serial.toLowerCase()).toSet();
    print("Ignoring hubIds: $hubIds");

    await _bleProvider.scan(
      timeout: const Duration(seconds: 10),
      onScanResult: (d, iosMac) {
        if (d.name.isEmpty) return false;
        setState(() => _curDevice = d);
        final mac = (iosMac ?? d.id.id).toLowerCase();
        print("Scanned peripheral ${d.name}, MAC $mac");
        if (d.name == HUB_NAME && !hubIds.contains(mac)) {
          print("Found Hub!");
          setState(() => _foundHub = d);
          return true;
        }
        return false;
      },
    );

    final isConnected = await _bleProvider.tryConnect(_foundHub);
    if (!isConnected) {
      print("no new devices connected and scan stopped");
      return _resetConn();
    }
    print(">>> Device fully connected");
    setState(() {
      _logText += "Connected to ${_foundHub!.name}\nDiscovering services...\n";
    });

    final commandChar = await _bleProvider.getChar(
      _foundHub!,
      HUB_SERVICE_UUID,
      COMMAND_CHARACTERISTIC_UUID,
    );
    if (commandChar == null) {
      print(">>> commandChar not found");
      return _resetConn();
    }

    setState(() => _logText += "Discovered all services\nWriting characteristic with userId...\n");

    String command = "UserId:${widget.userFrag.id}";
    print(">>> writing characteristic with value $command");
    await commandChar.write(utf8.encode(command));

    setState(() => _logText += "Wrote characteristic\nListening for response...");
    print(">>Starting rawHubId parse loop");

    String rawHubId = "";
    int startTime = DateTime.now().millisecondsSinceEpoch;
    while (rawHubId.length < 6 || !rawHubId.startsWith("HubId")) {
      print(">>attempting to read: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
      List<int> bytes = await commandChar.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawHubId = String.fromCharCodes(bytes);
      print(">>rawHubId = $rawHubId");
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() => _logText += ".");
      if (rawHubId.startsWith("Error:")) {
        setState(() => _errMsg = "Error:${rawHubId.substring(6)}");
        break;
      }
      if (DateTime.now().millisecondsSinceEpoch > startTime + 60000 || _foundHub == null) {
        setState(() => _errMsg = "Never received a response, likely a network error");
        break;
      }
    }

    if (_errMsg.isNotEmpty) {
      print(">>> Error: $_errMsg");
      await _foundHub?.disconnect();
      return;
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
    _bleProvider = Provider.of<BleProvider>(context, listen: true);
    Future<bool> cancelForm() async {
      _resetConn();
      context.vRouter.pop();
      return true;
    }

    return Mutation$AddVehicleWizardContent$Widget(
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
                        child: (Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              const Text(
                                "To get started, hold the pair button on the bottom of your HandleHub for 5 seconds",
                                textScaleFactor: 1.3,
                              ),
                              if (_curDevice != null) Text("...found ${_curDevice!.name}"),
                              if (_bleProvider.scanning && _logText.isEmpty)
                                const CircularProgressIndicator(),
                              if (!_bleProvider.scanning && _logText.isEmpty && _foundHub == null)
                                TextButton(
                                    key: const ValueKey("button.startScan"),
                                    onPressed: _findNewHub,
                                    child: const Text("Start scanning")),
                              if (_logText.isNotEmpty)
                                Text(key: const ValueKey("text.log"), _logText),
                              if (_errMsg.isNotEmpty) Text(_errMsg),
                            ])))),
                Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _foundHub == null || _errMsg != null ? cancelForm : null,
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
                            decoration:
                                const InputDecoration(hintText: "Name (eg. Year/Make/Model)"),
                            onChanged: (String name) => {setState(() => _hubCustomName = name)},
                            initialValue: _hubCustomName,
                          )
                        ])))),
                Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey("button.setName"),
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
