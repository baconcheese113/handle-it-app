import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_vehicle_wizard_content.mutation.graphql.dart';
import 'package:handle_it/feed/add_wizards/~graphql/__generated__/add_wizards.fragments.graphql.dart';
import 'package:handle_it/feed/~graphql/__generated__/feed_home.query.graphql.dart';
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

  String _hubCustomName = "";

  void setFormPage() {
    if (widget.pairedHubId != null) {
      final hubs = widget.userFrag.hubs;
      print(">>> Looking for ${widget.pairedHubId} and Hubs are ${hubs.map((h) => h.id)}");
      _hubCustomName = hubs.firstWhere((hub) => hub.id == widget.pairedHubId).name;
      _formsPageViewController!.animateToPage(1, duration: const Duration(milliseconds: 100), curve: Curves.ease);
    }
    print("HubCustomName is $_hubCustomName");
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
    });
  }

  Future<void> _findNewHub() async {
    if (!await _bleProvider.tryTurnOnBle()) return _resetConn();

    final hubIds = widget.userFrag.hubs.map((h) => h.serial.toLowerCase()).toSet();
    print("Ignoring hubIds: $hubIds");

    await _bleProvider.scan(
      timeout: const Duration(seconds: 10),
      onScanResult: (d) {
        if (d.name.isEmpty) return false;
        setState(() => _curDevice = d);
        print("Scanned peripheral ${d.name}, MAC ${d.id.id}");
        if (d.name == HUB_NAME && !hubIds.contains(d.id.id.toLowerCase())) {
          setState(() => _foundHub = d);
          return true;
        }
        return false;
      },
    );

    await _foundHub?.connect(timeout: const Duration(seconds: 10));
    final isConnected = (await _foundHub?.state.last) == BluetoothDeviceState.connected;
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
        return _resetConn();
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
    _bleProvider = Provider.of<BleProvider>(context, listen: true);
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
                          if (_bleProvider.scanning && _logText.isEmpty) const CircularProgressIndicator(),
                          if (!_bleProvider.scanning && _logText.isEmpty)
                            TextButton(
                                key: const ValueKey("button.startScan"),
                                onPressed: _findNewHub,
                                child: const Text("Start scanning")),
                          if (_logText.isNotEmpty) Text(key: const ValueKey("text.log"), _logText),
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
