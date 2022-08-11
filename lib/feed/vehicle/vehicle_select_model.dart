import 'package:flutter/material.dart';
import 'package:handle_it/feed/vehicle/car_query_api.dart';
import 'package:handle_it/feed/vehicle/vehicle_model_option.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_screen.query.graphql.dart';
import 'package:handle_it/feed/vehicle/~graphql/__generated__/vehicle_select_model.mutation.graphql.dart';
import 'package:vrouter/vrouter.dart';

class VehicleSelectModel extends StatefulWidget {
  const VehicleSelectModel({Key? key}) : super(key: key);

  static const routeName = "vehicle-select";

  @override
  State<VehicleSelectModel> createState() => _VehicleSelectModelState();
}

class _VehicleSelectModelState extends State<VehicleSelectModel> {
  int? _year;
  CarQueryMake? _make;
  CarQueryModel? _model;
  CarQueryTrim? _trim;

  List<int> _yearOpts = [];
  List<CarQueryMake> _makeOpts = [];
  List<CarQueryModel> _modelOpts = [];
  List<CarQueryTrim> _trimOpts = [];

  void _getYears() async {
    final years = await CarQueryApi.getYears();
    final numYears = years.maxYear - years.minYear;
    setState(() {
      _yearOpts = List.generate(numYears, (index) => years.maxYear - index);
    });
  }

  void _handleYearChange(int? newYear) async {
    final makes = newYear != null ? await CarQueryApi.getMakes(year: newYear) : null;
    setState(() {
      _year = newYear;
      _make = null;
      _model = null;
      _trim = null;
      _makeOpts = makes?.makes ?? [];
    });
  }

  void _handleMakeChange(CarQueryMake? newMake) async {
    final models = newMake != null ? await CarQueryApi.getModels(makeId: newMake.id, year: _year) : null;
    setState(() {
      _make = newMake;
      _model = null;
      _trim = null;
      _modelOpts = models?.models ?? [];
    });
  }

  void _handleModelChange(CarQueryModel? newModel) async {
    final trims = newModel != null
        ? await CarQueryApi.getTrims(
            makeId: _make?.id,
            year: _year,
            model: newModel.name,
          )
        : null;
    setState(() {
      _model = newModel;
      _trim = null;
      _trimOpts = trims?.trims ?? [];
    });
  }

  void _handleTrimChange(CarQueryTrim? newTrim) {
    setState(() => _trim = newTrim);
  }

  @override
  void initState() {
    _getYears();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final params = context.vRouter.pathParameters;
    final hubId = params["hubId"]!;

    final yearMenuItems = _yearOpts
        .map((y) => DropdownMenuItem(
              value: y,
              child: Text("$y"),
            ))
        .toList();
    final makeMenuItems = _makeOpts
        .map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.display),
            ))
        .toList();
    final modelMenuItems = _modelOpts
        .map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.name),
            ))
        .toList();

    final trimWidgets = _trimOpts.where((t) => _trim == null || t.id == _trim?.id).map((t) {
      return VehicleModelOption(
        trim: t,
        isSelected: t.id == _trim?.id,
        onSelect: () => _handleTrimChange(_trim == null ? t : null),
      );
    }).toList();

    return Mutation$CreateVehicle$Widget(options: WidgetOptions$Mutation$CreateVehicle(
      update: (cache, result) {
        if (result?.data == null) return;
        final vehicle = result!.parsedData!.createVehicle;
        final request = Options$Query$VehicleScreen(
          variables: Variables$Query$VehicleScreen(hubId: int.parse(hubId)),
        ).asRequest;
        final readQuery = cache.readQuery(request);
        if (readQuery == null) return;
        readQuery["hub"]["vehicle"] = vehicle.toJson();
        var map = Query$VehicleScreen.fromJson(readQuery);
        cache.writeQuery(request, data: map.toJson(), broadcast: true);
      },
    ), builder: (runMutation, result) {
      void handleSelect() async {
        await runMutation(
          Variables$Mutation$CreateVehicle(
            hubId: hubId,
            carQueryId: _trim!.id,
            year: _trim!.year,
            makeId: _trim!.makeId,
            modelName: _trim!.name,
            modelTrim: _trim!.trim,
            modelBody: _trim!.body,
          ),
        ).networkResult;
        context.vRouter.historyBack();
      }

      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Select Vehicle"),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Year"),
                DropdownButton(
                  value: _year,
                  items: yearMenuItems,
                  onChanged: _handleYearChange,
                ),
              ],
            ),
            if (_year != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("Make"),
                  DropdownButton<CarQueryMake>(
                    value: _make,
                    items: makeMenuItems,
                    onChanged: _handleMakeChange,
                  ),
                ],
              ),
            if (_make != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("Model"),
                  DropdownButton(
                    value: _model,
                    items: modelMenuItems,
                    onChanged: _handleModelChange,
                  ),
                ],
              ),
            if (_model != null)
              Expanded(
                flex: _trim == null ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView(
                    shrinkWrap: true,
                    children: trimWidgets,
                  ),
                ),
              ),
            if (_trim != null)
              TextButton(
                onPressed: handleSelect,
                child: const Text("Set as vehicle"),
              ),
          ],
        ),
      );
    });
  }
}
