import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle.fragments.graphql.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_notes.mutation.graphql.dart';

class VehicleNotes extends StatefulWidget {
  final Fragment$vehicleNotes_vehicle? vehicleFrag;
  const VehicleNotes({Key? key, required this.vehicleFrag}) : super(key: key);

  @override
  State<VehicleNotes> createState() => _VehicleNotesState();
}

class _VehicleNotesState extends State<VehicleNotes> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    if (widget.vehicleFrag == null) _controller.text = "";
    super.didChangeDependencies();
  }

  @override
  void initState() {
    final notes = widget.vehicleFrag?.notes ?? "";
    _controller.text = notes;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Mutation$UpdateVehicleNotes$Widget(
      builder: (runMutation, result) {
        void handleSubmit() async {
          await runMutation(
            Variables$Mutation$UpdateVehicleNotes(
              id: widget.vehicleFrag!.id.toString(),
              notes: _controller.text,
            ),
          ).networkResult;
        }

        return Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 16),
                child: Text("Additional notes"),
              ),
            ),
            TextField(
              enabled: widget.vehicleFrag != null,
              controller: _controller,
              onChanged: (newValue) => setState(() {}),
            ),
            TextButton(
              onPressed: _controller.text != (widget.vehicleFrag?.notes ?? "") ? handleSubmit : null,
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}
