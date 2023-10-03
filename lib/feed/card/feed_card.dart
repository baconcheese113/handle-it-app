import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/feed/card/feed_card_diagnostics.dart';
import 'package:handle_it/feed/card/feed_card_sensors.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/updaters/battery_status.dart';
import 'package:handle_it/feed/updaters/hub_updater.dart';
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
  bool _hasConnected = false;

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
      print(">>> New connection state is: $state and hasConnected: $_hasConnected");
      if (_deviceState == BluetoothDeviceState.disconnected && _hasConnected) {
        setState(() {
          _foundHub = null;
          _hasConnected = false;
        });
      }
      if (_deviceState == BluetoothDeviceState.connected) setState(() => _hasConnected = true);
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
      if (!_bleProvider.scanning && _deviceState == BluetoothDeviceState.disconnected) {
        return Colors.grey;
      }
      if (_deviceState == BluetoothDeviceState.connected) return Colors.green;
      return Colors.amber;
    }();

    final hubFrag = widget.hubFrag;
    final sensors = hubFrag.sensors;
    final events = sensors.fold<List<Fragment$feedCard_hub$sensors$events>>([], (arr, sensor) {
      return sensor.events.isNotEmpty ? [...arr, ...sensor.events] : arr;
    });

    final batLevel = _batteryLevel > -1 ? _batteryLevel : hubFrag.batteryLevel;

    return Card(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Column(children: [
            Icon(Icons.bluetooth, color: bluetoothIconColor),
            Text(hubFrag.version ?? "vX.X.X"),
          ]),
          title: Text("${hubFrag.name} (${hubFrag.serial})"),
          subtitle: Row(children: [
            if (_foundHub != null) FeedCardRssi(foundHub: _foundHub!, deviceState: _deviceState),
          ]),
          trailing: Column(children: [
            FeedCardMenu(hubFrag: hubFrag, onDelete: widget.onDelete),
            BatteryStatus(batteryLevel: batLevel, variant: Variant.small),
          ]),
        ),
        if (_foundHub == null && !_bleProvider.scanning)
          TextButton(onPressed: autoConnect, child: const Text("Connect")),
        if (_foundHub == null && _bleProvider.scanning)
          TextButton(onPressed: () => _bleProvider.stopScan(), child: const Text("Cancel Scan")),
        if (_foundHub != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _deviceState == BluetoothDeviceState.connected
                      ? HubUpdater(hubFrag: hubFrag, foundHub: _foundHub!)
                      : const SizedBox()),
              Container(color: Colors.white, width: 1, height: 45),
              Expanded(
                child: TextButton(
                  onPressed: () => _foundHub?.disconnect(),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Disconnect"),
                ),
              ),
            ],
          ),
        if (_foundHub != null) FeedCardDiagnostics(foundHub: _foundHub!),
        if (hubFrag.locations.isNotEmpty)
          SizedBox(height: 200, width: 400, child: FeedCardMap(hubFrag: hubFrag)),
        FeedCardSensors(hubFrag: hubFrag),
        if (events.isNotEmpty)
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
