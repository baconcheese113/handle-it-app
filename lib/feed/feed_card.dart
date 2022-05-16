import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_sensor_wizard.dart';
import 'package:handle_it/feed/feed_card_arm.dart';
import 'package:handle_it/feed/feed_card_delete.dart';
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
  '''), [FeedCardArm.feedCardArmFragment]);

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  int sensorValue = 0;
  bool armed = false;
  bool alarmTriggered = false;
  bool isConnectedBLE = false;

  void disarmAlarm() {
    setState(() {
      alarmTriggered = false;
      armed = false;
    });
  }

  void handleArmToggle() {
    if (armed) {
      disarmAlarm();
    } else {
      setState(() => armed = true);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void handleAddSensor() {
      Navigator.pushNamed(context, AddSensorWizard.routeName, arguments: {'hubId': widget.hubFrag['id']});
    }

    MaterialColor colorVal = () {
      if (!armed) return Colors.grey;
      if (alarmTriggered) return Colors.red;
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
              leading: Icon(Icons.bluetooth_connected, color: isConnectedBLE ? Colors.green : Colors.grey),
              title: Text("${widget.hubFrag['name']} (${widget.hubFrag['serial']})"),
              subtitle: Text("${widget.hubFrag['sensors'].length} Sensors | Outside BLE range"),
            ),
            TextButton(
              onPressed: handleAddSensor,
              child: const Text("Add sensor"),
            ),
            Center(
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(
                  Icons.directions_car,
                  size: 128,
                  color: colorVal,
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
