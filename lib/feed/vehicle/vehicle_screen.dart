import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/vehicle_color.dart';
import 'package:handle_it/feed/vehicle/vehicle_model.dart';
import 'package:handle_it/feed/vehicle/vehicle_notes.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_screen.query.graphql.dart';
import 'package:handle_it/utils.dart';
import 'package:vrouter/vrouter.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({Key? key}) : super(key: key);

  static const routeName = "/vehicle";

  @override
  Widget build(BuildContext context) {
    final params = context.vRouter.pathParameters;
    final hubId = int.parse(params["hubId"]!);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Vehicle Details"),
      ),
      body: Query$VehicleScreen$Widget(
        options: Options$Query$VehicleScreen(
          variables: Variables$Query$VehicleScreen(hubId: hubId),
        ),
        builder: (result, {fetchMore, refetch}) {
          final noDataWidget = validateResult(result);
          if (noDataWidget != null) return noDataWidget;

          final hub = result.parsedData!.hub!.vehicle;

          return ListView(
            children: [
              VehicleModel(vehicleFrag: hub),
              VehicleColor(vehicleFrag: hub),
              VehicleNotes(vehicleFrag: hub),
            ],
          );
        },
      ),
    );
  }
}
