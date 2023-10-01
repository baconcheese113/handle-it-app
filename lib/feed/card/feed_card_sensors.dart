import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/vehicle/vehicle_select_color.dart';

import '../updaters/battery_status.dart';

class FeedCardSensors extends StatefulWidget {
  final Fragment$feedCardSensors_hub hubFrag;

  const FeedCardSensors({super.key, required this.hubFrag});

  @override
  State<FeedCardSensors> createState() => _FeedCardSensorsState();
}

class _FeedCardSensorsState extends State<FeedCardSensors> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 0),
      vsync: this,
    ); //..repeat(reverse: true);

    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.purple).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensors = widget.hubFrag.sensors;
    final carColorObj = carColors.firstWhereOrNull((c) => c.name == widget.hubFrag.vehicle?.color);
    final carColor = carColorObj?.color;

    double? getTopValue(int sensorIdx) {
      final sensor = sensors[sensorIdx];
      if (sensor.doorColumn == 0) {
        if (sensor.doorRow == 0) return 30;
        return 10;
      }
    }

    double? getBottomValue(int sensorIdx) {
      final sensor = sensors[sensorIdx];
      if (sensor.doorColumn == 1) {
        if (sensor.doorRow == 0) return 20;
        return 60;
      }
    }

    double? getLeftValue(int sensorIdx) {
      final sensor = sensors[sensorIdx];
      if (sensor.doorColumn == 1) {
        if (sensor.doorRow == 0) return 100;
        return 10;
      }
    }

    double? getRightValue(int sensorIdx) {
      final sensor = sensors[sensorIdx];
      if (sensor.doorColumn == 0) {
        if (sensor.doorRow == 0) return 30;
        return 140;
      }
    }

    return Center(
      child: Stack(clipBehavior: Clip.none, children: [
        Image.asset("assets/images/vehicle_sedan.png"),
        // This is the car color
        Opacity(
          opacity: .77,
          child: Image.asset(
            "assets/images/vehicle_sedan_mask.png",
            color: carColor,
            colorBlendMode: BlendMode.modulate,
          ),
        ),
        // This is the background and ambient color
        AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: .1,
                child: Image.asset(
                  "assets/images/vehicle_sedan_mask.png",
                  color: _colorAnimation.value ?? Colors.white,
                  colorBlendMode: BlendMode.xor,
                ),
              );
            }),
        Positioned.fill(
          child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(.3))),
        ),
        if (sensors.isEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(.3)),
              child: const Center(
                child: Text("Please add a sensor", textScaleFactor: 1.2),
              ),
            ),
          ),
        for (int idx = 0; idx < sensors.length; idx++)
          Positioned(
            top: getTopValue(idx),
            bottom: getBottomValue(idx),
            left: getLeftValue(idx),
            right: getRightValue(idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: idx == 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  BatteryStatus(batteryLevel: sensors[idx].batteryLevel, variant: Variant.small),
                  Text('v${sensors[idx].version}',
                      style: sensors[idx].version != sensors[idx].latestVersion
                          ? const TextStyle(color: Colors.red)
                          : null),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}
