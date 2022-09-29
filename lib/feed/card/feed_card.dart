import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/updaters/battery_status.dart';
import 'package:handle_it/feed/updaters/hub_updater.dart';
import 'package:handle_it/feed/vehicle/vehicle_select_color.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../common/ble_provider.dart';
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
  BluetoothDevice? _foundHub;
  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateStreamSub;
  int _batteryLevel = -1;
  late BleProvider _bleProvider;

  void autoConnect() async {
    if (!await _bleProvider.hasBlePermissions()) return;
    await _bleProvider.scan(
        services: [Guid(HUB_SERVICE_UUID)],
        timeout: const Duration(seconds: 10),
        onScanResult: (d, iosMac) {
          final mac = (iosMac ?? d.id.id).toLowerCase();
          print("Scanned peripheral ${d.name}, MAC $mac");
          if (mac == widget.hubFrag.serial.toLowerCase()) {
            setState(() => _foundHub = d);
            return true;
          }
          return false;
        });
    _stateStreamSub = _foundHub?.state.listen((state) {
      setState(() => _deviceState = state);
      print(">>> New connection state is: $state");
    });
    final isConnected = await _bleProvider.tryConnect(_foundHub);
    if (!isConnected) {
      print("no devices connected and scan stopped");
      return;
    }

    final battLevelChar = await _bleProvider.getChar(
      _foundHub!,
      BATTERY_SERVICE_UUID,
      BATTERY_LEVEL_UUID,
    );
    if (battLevelChar == null) {
      print(">>> commandChar not found");
      return;
    }
    List<int> battLevelBytes = await battLevelChar.read();
    print(">>> battery level is ${battLevelBytes[0]}");
    setState(() => _batteryLevel = battLevelBytes[0]);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      autoConnect();
    });
  }

  @override
  void dispose() {
    _foundHub?.disconnect();
    _bleProvider.stopScan();
    _stateStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bleProvider = Provider.of<BleProvider>(context, listen: true);
    final bluetoothIconColor = () {
      if (!_bleProvider.scanning && _deviceState == BluetoothDeviceState.disconnected) return Colors.grey;
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
