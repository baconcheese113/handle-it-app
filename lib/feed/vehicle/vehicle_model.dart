import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/car_query_api.dart';
import 'package:handle_it/feed/vehicle/vehicle_delete.dart';
import 'package:handle_it/feed/vehicle/vehicle_model_option.dart';
import 'package:handle_it/feed/vehicle/vehicle_select_model.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle.fragments.graphql.dart';
import 'package:vrouter/vrouter.dart';

class VehicleModel extends StatefulWidget {
  final Fragment$vehicleModel_vehicle? vehicleFrag;
  const VehicleModel({Key? key, required this.vehicleFrag}) : super(key: key);

  @override
  State<VehicleModel> createState() => _VehicleModelState();
}

class _VehicleModelState extends State<VehicleModel> {
  CarQueryTrim? _trim;

  void fetchTrim() async {
    if (widget.vehicleFrag == null) return;
    final trim = await CarQueryApi.getTrim(
      modelId: widget.vehicleFrag!.carQueryId,
    );
    setState(() => _trim = trim);
  }

  @override
  void didChangeDependencies() {
    fetchTrim();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    fetchTrim();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hasVehicle = widget.vehicleFrag != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, top: 16),
          child: Text("Vehicle trim"),
        ),
        if (!hasVehicle)
          Card(
            child: ListTile(
              onTap: () => context.vRouter.to(VehicleSelectModel.routeName),
              leading: const Icon(Icons.car_repair),
              title: const Text("No Vehicle Selected"),
              subtitle: const Text("Tap to select"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        if (hasVehicle && _trim != null)
          VehicleModelOption(
            trim: _trim!,
            trailing: VehicleDelete(vehicleId: widget.vehicleFrag!.id),
          ),
        if (hasVehicle && _trim == null) const Card(child: CircularProgressIndicator()),
      ],
    );
  }
}
