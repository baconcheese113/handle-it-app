import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/car_query_api.dart';

class VehicleModelOption extends StatelessWidget {
  final CarQueryTrim trim;
  final bool? isSelected;
  final void Function()? onSelect;
  final Widget? trailing;
  const VehicleModelOption({
    Key? key,
    required this.trim,
    this.isSelected,
    this.onSelect,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seatStr = trim.numSeats == null ? "" : "${trim.numSeats} seat, ";
    final card = Card(
      child: ListTile(
        onTap: onSelect,
        title: Text("${trim.year} ${trim.makeDisplay} ${trim.name} ${trim.trim}"),
        subtitle: Text("${trim.numDoors} door, $seatStr${trim.engineCc}cc ${trim.body}"),
        trailing: trailing,
      ),
    );
    if (isSelected == null || !isSelected!) return card;
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent,
            blurRadius: 10.0,
          ),
        ],
      ),
      child: card,
    );
  }
}
