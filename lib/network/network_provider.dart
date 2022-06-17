import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const markerColors = [
  Colors.red,
  Colors.blueAccent,
  Colors.orange,
  Colors.cyan,
  Colors.green,
  Colors.purpleAccent,
  Colors.pink,
  Colors.deepPurple,
];
const markerHues = [
  BitmapDescriptor.hueRed,
  BitmapDescriptor.hueAzure,
  BitmapDescriptor.hueOrange,
  BitmapDescriptor.hueCyan,
  BitmapDescriptor.hueGreen,
  BitmapDescriptor.hueMagenta,
  BitmapDescriptor.hueRose,
  BitmapDescriptor.hueViolet,
];

class HubObject {
  int hubId;
  int networkId;
  LatLng loc;
  Color hue = Colors.black;
  HubObject(this.hubId, this.networkId, this.loc, {Color? hue});
}

class NetworkProvider extends ChangeNotifier {
  HubObject? selectedHub;
  Map<int, Color> networkColors = {};
  bool didAnimateToSelection = true;

  Color? getColorForId(int networkId) => networkColors[networkId];

  Color registerNetwork(int id) {
    Color? foundNetwork = getColorForId(id);
    if (foundNetwork != null) return foundNetwork;
    int nextIdx = networkColors.keys.length;
    return networkColors[id] = markerColors[nextIdx % markerColors.length];
  }

  double getMarkerHue(int networkId) {
    final idx = networkColors.keys.toList().indexWhere((nId) => nId == networkId);
    return markerHues[idx % markerHues.length];
  }

  setSelectedHub(HubObject newHub) {
    newHub.hue = networkColors[newHub.networkId]!;
    selectedHub = newHub;
    didAnimateToSelection = false;
    notifyListeners();
  }

  clearSelectedHub() {
    selectedHub = null;
    notifyListeners();
  }

  finishAnimate() {
    didAnimateToSelection = true;
    // notifyListeners();
  }
}
