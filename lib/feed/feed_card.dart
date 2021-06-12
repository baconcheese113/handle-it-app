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
  FeedCard({this.hubFrag, this.onDelete});

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
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  int sensorValue = 0;
  bool armed = false;
  bool alarmTriggered = false;
  bool isConnectedBLE = false;

  // TODO _bleManager.addListener(), then check if serial isConnected
  // void monitorHub() async {
  //   if (!await this.widget.hub.isConnected()) {
  //     print("Device not connected");
  //     return;
  //   }
  //   await this.widget.hub.discoverAllServicesAndCharacteristics();
  //   await for (CharacteristicWithValue c in this
  //       .widget
  //       .hub
  //       .monitorCharacteristic(HUB_SERVICE_UUID, SENSOR_VOLTS_CHARACTERISTIC_UUID, transactionId: 'monitor')) {
  //     if (!this.mounted) return; // we want to stop monitoring if this card is being disposed
  //     print("Characteristic ${c.uuid} has value ${c.value[0]}");
  //     setState(() {
  //       sensorValue = c.value[0];
  //       if (armed && sensorValue < 25) alarmTriggered = true;
  //     });
  //   }
  // }

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
    // monitorHub();
  }

  @override
  void dispose() {
    super.dispose();
    // print("Disposing of FeedCard that has ${this.widget.bleManager.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    void handleAddSensor() {
      Navigator.pushNamed(context, AddSensorWizard.routeName, arguments: {'hubId': this.widget.hubFrag['id']});
    }

    // void _handleDisconnect() {
    // this.widget.bleManager.cancelTransaction('monitor');
    // this.widget.hub.disconnectOrCancelConnection();
    // }

    // int sensorValInt = sensorValue != null ? sensorValue : 0;
    MaterialColor colorVal = () {
      if (!armed) return Colors.grey;
      if (alarmTriggered) return Colors.red;
      return Colors.green;
    }();
    if (!this.widget.hubFrag.containsKey('serial')) {
      return CircularProgressIndicator();
    }
    List<dynamic> sensors = this.widget.hubFrag['sensors'];
    List<dynamic> events = sensors.fold([], (arr, sensor) {
      final events = sensor['events'];
      return events.isNotEmpty ? [...arr, ...sensor['events']] : arr;
    });
    print("events $events");

    return Card(
        color: this.widget.hubFrag['isArmed'] ? null : Color.fromRGBO(255, 220, 220, 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(Icons.bluetooth_connected, color: isConnectedBLE ? Colors.green : Colors.grey),
              title: Text("${this.widget.hubFrag['name']} (${this.widget.hubFrag['serial']})"),
              subtitle: Text("${this.widget.hubFrag['sensors'].length} Sensors | Outside BLE range"),
            ),
            TextButton(
              onPressed: handleAddSensor,
              child: Text("Add sensor"),
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
              columns: [
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
                FeedCardArm(hub: this.widget.hubFrag),
                FeedCardDelete(hub: this.widget.hubFrag, onDelete: this.widget.onDelete),
              ],
            )
          ],
        ));
  }
}
