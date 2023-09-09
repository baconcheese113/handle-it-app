import 'package:flutter/material.dart';

enum Variant {
  normal,
  small,
}

class BatteryStatus extends StatelessWidget {
  final num? batteryLevel;
  final num? batteryVolts;
  final Variant variant;

  const BatteryStatus(
      {Key? key, this.batteryLevel, this.batteryVolts, this.variant = Variant.normal})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (variant == Variant.small) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 25,
          width: 55,
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.bolt, size: 16, color: Colors.white30),
                Text("$batteryLevel%")
              ]),
              if (batteryLevel != null)
                LinearProgressIndicator(
                    backgroundColor: Colors.white30, value: batteryLevel! / 100, minHeight: 1),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: 50,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (batteryLevel != null)
            CircularProgressIndicator(backgroundColor: Colors.white10, value: batteryLevel! / 100),
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("$batteryLevel%"),
            if (batteryVolts != null) Text("${(batteryVolts! / 1000).toStringAsFixed(1)}v")
          ])),
          const Icon(Icons.battery_full_outlined,
              color: Color.fromRGBO(255, 255, 255, .3), size: 48)
        ],
      ),
    );
  }
}
