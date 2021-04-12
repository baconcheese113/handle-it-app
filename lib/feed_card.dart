import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:handle_it/add_vehicle_wizard.dart';

class FeedCard extends StatefulWidget {
  final Peripheral hub;
  final String name;
  final BleManager bleManager;
  final Function onDisconnect;
  FeedCard({this.hub, this.name, this.bleManager, this.onDisconnect});

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  int sensorValue = 0;
  bool armed = false;
  bool alarmTriggered = false;

  void monitorHub() async {
    if (!await this.widget.hub.isConnected()) {
      print("Device not connected");
      return;
    }
    await this.widget.hub.discoverAllServicesAndCharacteristics();
    await for (CharacteristicWithValue c in this
        .widget
        .hub
        .monitorCharacteristic(HUB_SERVICE_UUID, SENSOR_VOLTS_CHARACTERISTIC_UUID, transactionId: 'monitor')) {
      if (!this.mounted) return; // we want to stop monitoring if this card is being disposed
      print("Characteristic ${c.uuid} has value ${c.value[0]}");
      setState(() {
        sensorValue = c.value[0];
        if (armed && sensorValue < 25) alarmTriggered = true;
      });
    }
  }

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
    monitorHub();
  }

  @override
  void dispose() {
    super.dispose();
    print("Disposing of FeedCard that has ${this.widget.bleManager.toString()}");
  }

  void _handleDisconnect() {
    this.widget.bleManager.cancelTransaction('monitor');
    this.widget.hub.disconnectOrCancelConnection();
    this.widget.onDisconnect();
  }

  @override
  Widget build(BuildContext context) {
    int sensorValInt = sensorValue != null ? sensorValue : 0;
    MaterialColor colorVal = () {
      if (!armed) return Colors.grey;
      if (alarmTriggered) return Colors.red;
      return Colors.green;
    }();
    return Card(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.bluetooth_connected, color: Colors.green),
          title: Text(this.widget.name),
          subtitle: Text("Status: 1 Sensor Connected"),
        ),
        TextButton(
          onPressed: handleArmToggle,
          child: Text(armed ? "Disarm" : "Arm"),
        ),
        Center(
            child: Stack(clipBehavior: Clip.none, children: [
          Icon(
            Icons.directions_car,
            size: 128,
            color: colorVal,
          ),
          // Positioned(
          //   top: 30,
          //   left: -40,
          //   child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          //     Text(sensorValue.toString()),
          //     Icon(Icons.shield, size: 32, color: Colors.green),
          //     Text(
          //       "Secure",
          //       textScaleFactor: 1.1,
          //     )
          //   ]),
          // ),
          Positioned(
            top: 30,
            right: -60,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  height: 20,
                  width: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38, width: 0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: LinearProgressIndicator(
                    value: (sensorValInt).toDouble() / 30.0,
                    backgroundColor: Colors.white70,
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 8), child: Text(sensorValInt.toString()))
              ]),
              Icon(sensorValInt > 25 ? Icons.shield : Icons.error, size: 32, color: colorVal),
              Text(sensorValInt > 25 ? "Secure" : "Opened", textScaleFactor: 1.1)
            ]),
          ),
        ])),
        DataTable(columns: [
          DataColumn(label: Text("Time")),
          DataColumn(label: Text("Event")),
        ], rows: [
          if (alarmTriggered)
            DataRow(cells: [
              DataCell(Text("1s ago")),
              DataCell(Text("Left Handle pulled")),
            ]),
          DataRow(cells: [
            DataCell(Text("21d ago")),
            DataCell(Text("Left Handle pulled")),
          ]),
        ]),
        TextButton(onPressed: _handleDisconnect, child: Text("Disconnect")),
      ],
    ));
  }
}
