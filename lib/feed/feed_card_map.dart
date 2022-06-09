import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class FeedCardMap extends StatefulWidget {
  final Map<String, dynamic> hub;
  const FeedCardMap({Key? key, required this.hub}) : super(key: key);

  static final feedCardMapFragment = gql(r'''
    fragment feedCardMap_hub on Hub {
      id
      locations(last: 2) {
        id
        lat
        lng
        hdop
        speed
        age
        course
      }
    }
  ''');

  @override
  State<FeedCardMap> createState() => _FeedCardMapState();
}

class _FeedCardMapState extends State<FeedCardMap> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> locations = widget.hub['locations'];
    if (locations.isEmpty) {
      return const Center(child: Text("Add GPS module to see location"));
    }
    print(">>> locations: $locations");
    final firstLatLng = LatLng(locations[0]['lat'], locations[0]['lng']);
    print(">>> firstLatLng = $firstLatLng");
    double alpha = 1;
    final markers = locations.reversed.map((l) {
      final pos = LatLng(l['lat'], l['lng']);
      alpha -= .3;
      return Marker(markerId: MarkerId("${l['id']}"), position: pos, alpha: alpha);
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: firstLatLng, zoom: 16.0),
      myLocationEnabled: false,
      buildingsEnabled: true,
      zoomGesturesEnabled: false,
      zoomControlsEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      compassEnabled: false,
      myLocationButtonEnabled: false,
      markers: markers,
    );
  }
}
