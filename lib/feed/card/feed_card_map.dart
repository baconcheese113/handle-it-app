import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';

class FeedCardMap extends StatelessWidget {
  final Fragment$feedCardMap_hub hubFrag;
  const FeedCardMap({Key? key, required this.hubFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locations = hubFrag.locations;
    if (locations.isEmpty) {
      return const Center(child: Text("Add GPS module to see location"));
    }
    final firstLatLng = LatLng(locations[0].lat, locations[0].lng);
    double alpha = 1;
    final markers = locations.reversed.map((l) {
      final pos = LatLng(l.lat, l.lng);
      alpha -= .3;
      return Marker(markerId: MarkerId("${l.id}"), position: pos, alpha: alpha);
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
