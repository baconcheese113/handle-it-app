import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_delete.mutation.graphql.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_screen.query.graphql.dart';
import 'package:vrouter/vrouter.dart';

class VehicleDelete extends StatelessWidget {
  final int vehicleId;
  const VehicleDelete({Key? key, required this.vehicleId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final params = context.vRouter.pathParameters;
    final hubId = int.parse(params["hubId"]!);

    return Mutation$DeleteVehicle$Widget(
      options: WidgetOptions$Mutation$DeleteVehicle(
        update: (cache, result) {
          if (result?.data == null) return;
          final id = result!.parsedData!.deleteVehicle!.id;
          final request = Options$Query$VehicleScreen(
            variables: Variables$Query$VehicleScreen(hubId: hubId),
          ).asRequest;
          final readQuery = cache.readQuery(request);
          if (readQuery == null) return;
          if (readQuery["hub"]["vehicle"]["id"] == id) {
            readQuery["hub"]["vehicle"] = null;
          }
          var map = Query$VehicleScreen.fromJson(readQuery);
          cache.writeQuery(request, data: map.toJson(), broadcast: true);
        },
      ),
      builder: (runMutation, result) {
        void handleDelete() {
          runMutation(
            Variables$Mutation$DeleteVehicle(id: vehicleId.toString()),
          ).networkResult;
        }

        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: handleDelete,
        );
      },
    );
  }
}
