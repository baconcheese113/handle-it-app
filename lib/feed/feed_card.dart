import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_sensor_wizard.dart';
import 'package:handle_it/feed/add_vehicle_wizard_content.dart';
import 'package:handle_it/feed/feed_card_arm.dart';
import 'package:handle_it/feed/feed_card_delete.dart';
import 'package:handle_it/feed/updater.dart';
import 'package:handle_it/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedCard extends StatefulWidget {
  final Map<String, dynamic> hubFrag;
  final Function onDelete;
  const FeedCard({Key? key, required this.hubFrag, required this.onDelete}) : super(key: key);

  static final feedCardFragment = addFragments(gql(r'''
    fragment feedCard_hub on Hub {
      id
      name
      serial
      isArmed
      ...feedCardArm_hub
      ...updater_hub
      sensors {
        id
        serial
        isOpen
        isConnected
        doorRow
        doorColumn
        events(orderBy: [{ createdAt: desc }]) {
          id
          createdAt
          sensor {
            id
            doorColumn
            doorRow
          }
        }
      }
    }
  '''), [FeedCardArm.feedCardArmFragment, Updater.updaterFragment]);

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _armed = false;
  bool _scanning = false;
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundHub;
  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateStreamSub;

  void handleArmToggle() {
    setState(() => _armed = !_armed);
  }

  void autoConnect() async {
    await _flutterBlue.stopScan();
    setState(() => _scanning = true);
    print("bluetooth state is now POWERED_ON, starting peripheral scan");
    await for (final r
        in _flutterBlue.scan(withServices: [Guid(HUB_SERVICE_UUID)], timeout: const Duration(seconds: 10))) {
      print("Scanned peripheral ${r.device.name}, RSSI ${r.rssi}");
      _flutterBlue.stopScan();
      setState(() => _foundHub = r.device);
      break;
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
    void handleAddSensor() {
      Navigator.pushNamed(context, AddSensorWizard.routeName, arguments: {'hubId': widget.hubFrag['id']});
    }

    final bluetoothIconColor = () {
      if (!_scanning && _deviceState == BluetoothDeviceState.disconnected) return Colors.grey;
      if (_deviceState == BluetoothDeviceState.connected) return Colors.green;
      return Colors.amber;
    }();

    MaterialColor isArmedColor = () {
      if (!_armed) return Colors.grey;
      return Colors.green;
    }();
    if (!widget.hubFrag.containsKey('serial')) {
      return const CircularProgressIndicator();
    }
    List<dynamic> sensors = widget.hubFrag['sensors'];
    List<dynamic> events = sensors.fold([], (arr, sensor) {
      final events = sensor['events'];
      return events.isNotEmpty ? [...arr, ...sensor['events']] : arr;
    });
    print("events $events");

    return Card(
        color: widget.hubFrag['isArmed'] ? null : const Color.fromRGBO(255, 220, 220, 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(Icons.bluetooth, color: bluetoothIconColor),
              title: Text("${widget.hubFrag['name']} (${widget.hubFrag['serial']})"),
              subtitle: Text("${widget.hubFrag['sensors'].length} Sensors | Outside BLE range"),
            ),
            TextButton(
              onPressed: handleAddSensor,
              child: const Text("Add sensor"),
            ),
            if (_foundHub != null && _deviceState == BluetoothDeviceState.connected)
              Updater(hub: widget.hubFrag, foundHub: _foundHub!),
            Center(
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(
                  Icons.directions_car,
                  size: 128,
                  color: isArmedColor,
                ),
                for (int idx = 0; idx < sensors.length; idx++)
                  Positioned(
                    top: 30,
                    left: idx == 0 ? -40 : null,
                    right: idx == 1 ? -40 : null,
                    child: Column(
                      crossAxisAlignment: idx == 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Icon(sensors[idx]['isOpen'] == true ? Icons.error : Icons.shield,
                            size: 32, color: sensors[idx]['isOpen'] ? Colors.red : Colors.green),
                        Text(sensors[idx]['isOpen'] ? "Opened" : "Secure", textScaleFactor: 1.1)
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
                final column = event['sensor']['doorColumn'] == 0 ? 'Front' : 'Back';
                final row = event['sensor']['doorRow'] == 0 ? 'left' : 'right';
                return DataRow(cells: [
                  DataCell(Text(timeago.format(DateTime.parse(event['createdAt'])))),
                  DataCell(Text("$column $row handle pulled")),
                ]);
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FeedCardArm(hub: widget.hubFrag),
                FeedCardDelete(hub: widget.hubFrag, onDelete: widget.onDelete),
              ],
            )
          ],
        ));
  }
}
