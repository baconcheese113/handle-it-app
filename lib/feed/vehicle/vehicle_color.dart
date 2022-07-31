import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/vehicle_select_color.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle.fragments.graphql.dart';
import 'package:vrouter/vrouter.dart';

class VehicleColor extends StatelessWidget {
  final Fragment$vehicleColor_vehicle? vehicleFrag;
  const VehicleColor({Key? key, required this.vehicleFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final carColor = carColors.firstWhereOrNull((c) => c.name == vehicleFrag?.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, top: 16),
          child: Text("Vehicle color"),
        ),
        Card(
          child: ListTile(
            enabled: vehicleFrag != null,
            onTap: () => context.vRouter.to("${VehicleSelectColor.routeName}/${vehicleFrag!.id}"),
            leading: Icon(Icons.brush, color: carColor?.color),
            title: Text(carColor == null ? "No Color Selected" : carColor.name),
            subtitle: Text("Tap to ${carColor == null ? "select" : "change"}"),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
