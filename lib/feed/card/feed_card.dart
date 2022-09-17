import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/updaters/battery_status.dart';
import 'package:handle_it/feed/updaters/hub_updater.dart';
import 'package:handle_it/feed/vehicle/vehicle_select_color.dart';
import 'package:handle_it/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../add_wizards/add_vehicle_wizard_content.dart';
import '../updaters/sensor_updater.dart';
import 'feed_card_arm.dart';
import 'feed_card_map.dart';
import 'feed_card_menu.dart';
import 'feed_card_rssi.dart';

class FeedCard extends StatefulWidget {
  final Fragment$feedCard_hub hubFrag;
  final Function onDelete;
  const FeedCard({Key? key, required this.hubFrag, required this.onDelete}) : super(key: key);

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _scanning = false;
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundHub;
  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateStreamSub;
  int _batteryLevel = -1;

  void autoConnect() async {
    await _flutterBlue.stopScan();
    setState(() => _scanning = true);
    print("bluetooth state is now POWERED_ON, starting peripheral scan");
    await for (final r
        in _flutterBlue.scan(withServices: [Guid(HUB_SERVICE_UUID)], timeout: const Duration(seconds: 10))) {
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}, MAC ${r.device.id.id}");
      if (r.device.id.id.toLowerCase() == widget.hubFrag.serial.toLowerCase()) {
        _flutterBlue.stopScan();
        setState(() => _foundHub = r.device);
        break;
      }
    }
    if (mounted) setState(() => _scanning = false);
    if (_foundHub == null) {
      print("no devices found and scan stopped");
      return;
    }

    _stateStreamSub = _foundHub!.state.listen((state) {
      setState(() => _deviceState = state);
      print(">>> New connection state is: $state");
    });

    print(">>> connecting");
    await _foundHub!.connect();
    print(">>> connecting finished");

    final services = await _foundHub!.discoverServices();
    final battService = services.firstWhere((s) => s.uuid == Guid(BATTERY_SERVICE_UUID));
    final battLevelChar = battService.characteristics.firstWhere((c) => c.uuid == Guid(BATTERY_LEVEL_UUID));
    List<int> battLevelBytes = await battLevelChar.read();
    print(">>> battery level is ${battLevelBytes[0]}");
    setState(() => _batteryLevel = battLevelBytes[0]);
  }

  @override
  void initState() {
    autoConnect();
    super.initState();
  }

  @override
  void dispose() {
    _foundHub?.disconnect();
    _flutterBlue.stopScan();
    _stateStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothIconColor = () {
      if (!_scanning && _deviceState == BluetoothDeviceState.disconnected) return Colors.grey;
      if (_deviceState == BluetoothDeviceState.connected) return Colors.green;
      return Colors.amber;
    }();

    final hubFrag = widget.hubFrag;
    final sensors = hubFrag.sensors;
    final events = sensors.fold<List<Fragment$feedCard_hub$sensors$events>>([], (arr, sensor) {
      return sensor.events.isNotEmpty ? [...arr, ...sensor.events] : arr;
    });
    final int sensorCount = sensors.length;

    final carColor = carColors.firstWhereOrNull((c) => c.name == hubFrag.vehicle?.color);

    return Card(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.bluetooth, color: bluetoothIconColor),
          title: Text("${hubFrag.name} (${hubFrag.serial})"),
          subtitle: Row(children: [
            Text("${pluralize('sensor', sensorCount)} |"),
            FeedCardRssi(foundHub: _foundHub, deviceState: _deviceState),
          ]),
          trailing: Column(children: [
            FeedCardMenu(hubFrag: hubFrag, onDelete: widget.onDelete),
            if (_batteryLevel > -1) BatteryStatus(batteryLevel: _batteryLevel, variant: Variant.small),
          ]),
        ),
        if (_foundHub != null && _deviceState == BluetoothDeviceState.connected)
          Center(child: HubUpdater(hubFrag: hubFrag, foundHub: _foundHub!)),
        SizedBox(height: 200, width: 400, child: FeedCardMap(hubFrag: hubFrag)),
        Center(
          child: Stack(clipBehavior: Clip.none, children: [
            Icon(
              Icons.directions_car,
              size: 128,
              color: carColor?.color,
            ),
            for (int idx = 0; idx < sensors.length; idx++)
              Positioned(
                top: 30,
                left: idx == 0 ? -40 : null,
                right: idx == 1 ? -40 : null,
                child: Column(
                  crossAxisAlignment: idx == 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Icon(sensors[idx].isOpen == true ? Icons.error : Icons.shield,
                        size: 32, color: sensors[idx].isOpen ? Colors.red : Colors.green),
                    Text(sensors[idx].isOpen ? "Opened" : "Secure", textScaleFactor: 1.1)
                  ],
                ),
              ),
          ]),
        ),
        DataTable(
          columns: const [
            DataColumn(label: Text("Time")),
            DataColumn(label: Text("Event")),
          ],
          rows: events.map((event) {
            final column = event.sensor.doorColumn == 0 ? 'Front' : 'Back';
            final row = event.sensor.doorRow == 0 ? 'left' : 'right';
            return DataRow(cells: [
              DataCell(Text(timeago.format(event.createdAt))),
              DataCell(Text("$column $row handle pulled")),
            ]);
          }).toList(),
        ),
        FeedCardArm(hubFrag: hubFrag),
      ],
    ));
  }
}
