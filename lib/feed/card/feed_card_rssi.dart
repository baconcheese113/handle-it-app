import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

num calcDistance(int rssi) {
  const environmentFactor = 2;
  return pow(10, ((-58 - rssi) / (10 * environmentFactor)));
}

class FeedCardRssi extends StatefulWidget {
  final BluetoothDevice? foundHub;
  final BluetoothDeviceState deviceState;
  const FeedCardRssi({Key? key, required this.foundHub, required this.deviceState}) : super(key: key);

  @override
  State<FeedCardRssi> createState() => _FeedCardRssiState();
}

class _FeedCardRssiState extends State<FeedCardRssi> {
  // -2 before subscription started, -1 when started, 0+ when set
  num _distance = -2;

  void subscribeToRssi() async {
    print(">>> subscribed");
    if (widget.foundHub == null) return;
    setState(() => _distance = -1);
    final startRssi = await widget.foundHub!.readRssi();
    final rssiBuffer = List.filled(10, calcDistance(startRssi));
    int bufferPlace = 0;
    Stream.periodic(const Duration(seconds: 2))
        .takeWhile((element) => mounted && widget.foundHub != null)
        .forEach((_) async {
      final rssi = await widget.foundHub!.readRssi();
      final distance = calcDistance(rssi);
      rssiBuffer[bufferPlace] = distance;
      bufferPlace = (bufferPlace + 1) % rssiBuffer.length;
      final smoothDistance = rssiBuffer.reduce((value, element) => value + element) / rssiBuffer.length;
      setState(() => _distance = smoothDistance);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kick off rssi subscription when foundHub is set, but only once
    if (widget.foundHub != null && widget.deviceState == BluetoothDeviceState.connected && _distance == -2) {
      subscribeToRssi();
    }

    final rangeStr = () {
      if (_distance == -2) return "Not connected";
      if (_distance == -1) return "Calculating...";
      if (_distance < 2) return "<1 meter";
      return "${_distance.round()} meters";
    }();
    return Expanded(child: Text(" $rangeStr"));
  }
}
