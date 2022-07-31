import 'dart:convert';

import 'package:http/http.dart';

class CarQueryApi {
  static const endpoint = "https://www.carqueryapi.com/api/0.3/";

  static Future<T> fetchAndDecode<T extends CarQuery>(Map<String, String> params) async {
    final uri = Uri.parse(endpoint);
    final response = await get(uri.replace(queryParameters: params));
    if (response.statusCode == 200) {
      return CarQuery<T>.fromJson(jsonDecode(response.body)) as T;
    } else {
      throw Exception("Failed to load from car query api");
    }
  }

  static Future<CarQueryYears> getYears() async {
    return fetchAndDecode<CarQueryYears>({"cmd": "getYears"});
  }

  static Future<CarQueryMakes> getMakes({int? year}) async {
    final params = {"cmd": "getMakes"};
    if (year != null) params["year"] = "$year";
    return fetchAndDecode<CarQueryMakes>(params);
  }

  static Future<CarQueryModels> getModels({String? makeId, int? year}) async {
    final params = {"cmd": "getModels"};
    if (makeId != null) params["make"] = makeId;
    if (year != null) params["year"] = "$year";
    return fetchAndDecode<CarQueryModels>(params);
  }

  static Future<CarQueryTrims> getTrims({String? makeId, int? year, String? model}) async {
    final params = {"cmd": "getTrims"};
    if (makeId != null) params["make"] = makeId;
    if (year != null) params["year"] = "$year";
    if (model != null) params["model"] = model;
    return fetchAndDecode<CarQueryTrims>(params);
  }

  static Future<CarQueryTrim> getTrim({required String modelId}) async {
    final params = {"cmd": "getModel", "model": modelId};
    return fetchAndDecode<CarQueryTrim>(params);
  }
}

abstract class CarQuery<T> {
  CarQuery();
  factory CarQuery.fromJson(dynamic json) {
    if (T == CarQueryYears) {
      return CarQueryYears.fromJson(json) as CarQuery<T>;
    }
    if (T == CarQueryMakes) {
      return CarQueryMakes.fromJson(json) as CarQuery<T>;
    }
    if (T == CarQueryModels) {
      return CarQueryModels.fromJson(json) as CarQuery<T>;
    }
    if (T == CarQueryTrims) {
      return CarQueryTrims.fromJson(json) as CarQuery<T>;
    }
    if (T == CarQueryTrim) {
      return CarQueryTrim.fromJson(json) as CarQuery<T>;
    }

    throw UnimplementedError("Unimplemented type for $T");
  }
}

class CarQueryYears implements CarQuery<CarQueryYears> {
  late int minYear, maxYear;
  CarQueryYears(this.minYear, this.maxYear);

  factory CarQueryYears.fromJson(Map<String, dynamic> json) {
    return CarQueryYears(
      int.parse(json["Years"]["min_year"]),
      int.parse(json["Years"]["max_year"]),
    );
  }
}

class CarQueryMake {
  final String id, display, country;
  final bool isCommon;
  CarQueryMake(this.id, this.display, this.country, this.isCommon);
}

class CarQueryMakes implements CarQuery<CarQueryMakes> {
  List<CarQueryMake> makes;
  CarQueryMakes(this.makes);

  factory CarQueryMakes.fromJson(Map<String, dynamic> json) {
    final List<dynamic> arr = json["Makes"];
    return CarQueryMakes(arr
        .map((m) => CarQueryMake(
              m["make_id"]!,
              m["make_display"]!,
              m["make_is_common"]!,
              m["make_country"] == "1",
            ))
        .toList());
  }
}

class CarQueryModel {
  final String name, makeId;
  CarQueryModel(this.name, this.makeId);
}

class CarQueryModels implements CarQuery<CarQueryModels> {
  List<CarQueryModel> models;
  CarQueryModels(this.models);

  factory CarQueryModels.fromJson(Map<String, dynamic> json) {
    final List<dynamic> arr = json["Models"];
    return CarQueryModels(arr
        .map((m) => CarQueryModel(
              m["model_name"]!,
              m["model_make_id"]!,
            ))
        .toList());
  }
}

class CarQueryTrim implements CarQuery<CarQueryTrim> {
  final String id, name, trim, body, makeId, makeDisplay, makeCountry;
  final String? drive, transmission, enginePos, engineCc, engineCyl, engineFuel;
  final int year;
  final int? numSeats, numDoors;
  CarQueryTrim({
    required this.id,
    required this.name,
    required this.trim,
    required this.year,
    required this.body,
    this.numSeats,
    this.numDoors,
    required this.makeId,
    required this.makeDisplay,
    required this.makeCountry,
    this.drive,
    this.transmission,
    this.enginePos,
    this.engineCc,
    this.engineCyl,
    this.engineFuel,
  });
  factory CarQueryTrim.fromJson(List<dynamic> json) {
    final Map<String, dynamic> t = json[0];
    return CarQueryTrim(
      id: t["model_id"]!,
      name: t["model_name"]!,
      trim: t["model_trim"]!,
      year: int.parse(t["model_year"]!),
      body: t["model_body"]!,
      numSeats: int.tryParse(t["model_seats"] ?? ""),
      numDoors: int.tryParse(t["model_doors"] ?? ""),
      makeId: t["model_make_id"]!,
      makeDisplay: t["make_display"]!,
      makeCountry: t["make_country"]!,
      drive: t["model_drive"],
      transmission: t["model_transmission_type"],
      enginePos: t["model_engine_position"],
      engineCc: t["model_engine_cc"],
      engineCyl: t["model_engine_cyl"],
      engineFuel: t["model_engine_fuel"],
    );
  }
}

class CarQueryTrims implements CarQuery<CarQueryTrims> {
  List<CarQueryTrim> trims;
  CarQueryTrims(this.trims);

  factory CarQueryTrims.fromJson(Map<String, dynamic> json) {
    final List<dynamic> arr = json["Trims"];
    return CarQueryTrims(arr
        .map((t) => CarQueryTrim(
              id: t["model_id"]!,
              name: t["model_name"]!,
              trim: t["model_trim"]!,
              year: int.parse(t["model_year"]),
              body: t["model_body"]!,
              numSeats: int.tryParse(t["model_seats"] ?? ""),
              numDoors: int.tryParse(t["model_doors"] ?? ""),
              makeId: t["model_make_id"]!,
              makeDisplay: t["make_display"]!,
              makeCountry: t["make_country"]!,
              drive: t["model_drive"],
              transmission: t["model_transmission_type"],
              enginePos: t["model_engine_position"],
              engineCc: t["model_engine_cc"],
              engineCyl: t["model_engine_cyl"],
              engineFuel: t["model_engine_fuel"],
            ))
        .toList());
  }
}
