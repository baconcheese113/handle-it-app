import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_select_color.mutation.graphql.dart';
import 'package:vrouter/vrouter.dart';

class CarColor {
  final Color color;
  final String name;
  CarColor(this.color, this.name);
}

final carColors = [
  CarColor(Colors.white, "white"),
  CarColor(Colors.black, "black"),
  CarColor(const Color.fromRGBO(169, 169, 169, 1), "dark grey"),
  CarColor(const Color.fromRGBO(128, 128, 128, 1), "grey"),
  CarColor(const Color.fromRGBO(192, 192, 192, 1), "silver"),
  CarColor(Colors.red, "red"),
  CarColor(Colors.blue, "blue"),
  CarColor(Colors.brown, "brown"),
  CarColor(Colors.green, "green"),
  CarColor(const Color.fromRGBO(245, 245, 220, 1), "beige"),
  CarColor(Colors.orange, "orange"),
  CarColor(const Color.fromRGBO(255, 215, 0, 1), "gold"),
  CarColor(Colors.yellow, "yellow"),
  CarColor(Colors.purple, "purple"),
];

class VehicleSelectColor extends StatefulWidget {
  const VehicleSelectColor({Key? key}) : super(key: key);

  static const routeName = "vehicle-color";
  @override
  State<VehicleSelectColor> createState() => _VehicleSelectColorState();
}

class _VehicleSelectColorState extends State<VehicleSelectColor> {
  CarColor? _selectedColor;

  void _handleColorSelect(CarColor newColor) {
    setState(() => _selectedColor = _selectedColor == newColor ? null : newColor);
  }

  @override
  Widget build(BuildContext context) {
    final params = context.vRouter.pathParameters;
    final vehicleId = params["vehicleId"]!;

    return Mutation$UpdateVehicleColor$Widget(
      builder: (runMutation, result) {
        void handleSubmit() async {
          await runMutation(
            Variables$Mutation$UpdateVehicleColor(
              id: vehicleId,
              color: _selectedColor!.name,
            ),
          ).networkResult;
          context.vRouter.pop();
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Select Color"),
          ),
          body: Column(
            children: [
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  children: carColors.map((c) {
                    final isSelected = _selectedColor?.name == c.name;
                    final isLight = c.color.computeLuminance() > .3;
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => _handleColorSelect(c),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white60, width: 8),
                            borderRadius: BorderRadius.circular(50),
                            color: c.color,
                            boxShadow: isSelected
                                ? [
                                    const BoxShadow(
                                      color: Colors.amberAccent,
                                      blurRadius: 20.0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isLight ? Colors.black : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: _selectedColor == null ? null : handleSubmit,
                child: const Text("Select Color"),
              )
            ],
          ),
        );
      },
    );
  }
}
