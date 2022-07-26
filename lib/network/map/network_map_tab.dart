import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handle_it/network/map/network_map_details.dart';
import 'package:handle_it/network/map/~graphql/__generated__/map.fragments.graphql.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

Future<Uint8List> getCustomMarker(Color color, String name, bool isAlert, bool isSelected) async {
  final PictureRecorder pictureRecorder = PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final length = isSelected ? 200.0 : 120.0;
  final width = length ~/ 1;
  final height = length ~/ 1;

  final circlePaint = Paint()..color = Colors.white.withOpacity(.6);
  canvas.drawCircle(Offset(length / 2, length / 2), length * .40, circlePaint);

  final icon = isAlert ? Icons.priority_high : Icons.directions_car;
  TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontSize: length * .75,
        fontFamily: icon.fontFamily,
      ),
    )
    ..layout()
    ..paint(canvas, Offset(length * .25 / 2, 20));
  if (isAlert) {
    final alertPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: "ALERT",
        style: TextStyle(color: color, fontSize: length * .2, fontWeight: FontWeight.bold),
      )
      ..layout();
    alertPainter.paint(canvas, Offset((length - alertPainter.width) / 2, 0));
  }
  final paint = Paint()
    ..strokeWidth = 8.0
    ..color = color;
  canvas.drawLine(
    Offset(length * .25, length * .75),
    Offset(length / 2, length),
    paint,
  );
  canvas.drawLine(
    Offset(length / 2, length),
    Offset(length * .75, length * .75),
    paint,
  );
  final img = await pictureRecorder.endRecording().toImage(width, height);
  final data = await img.toByteData(format: ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class NetworkMapTab extends StatefulWidget {
  final Fragment$networkMapTab_viewer viewerFrag;
  final Function refetch;
  const NetworkMapTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  @override
  State<NetworkMapTab> createState() => _NetworkMapTabState();
}

class _NetworkMapTabState extends State<NetworkMapTab> {
  GoogleMapController? _mapController;

  void handleMapCreated(GoogleMapController mapController) {
    if (mounted) setState(() => _mapController = mapController);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final netProvider = Provider.of<NetworkProvider>(context);
    final networks = widget.viewerFrag.activeNetworks;
    final List<int> addedHubs = [];
    LatLng? bestCameraPos;
    Set<Circle> circles = {};

    Future<List<Marker>> getMarkerWidgets(int networkId, int idx) async {
      final network = networks.firstWhere((n) => n.id == networkId);
      final members = network.members;
      final List<Marker> markers = [];
      for (final m in members) {
        final hubs = m.user.hubs;
        for (final hub in hubs) {
          final int hubId = hub.id;
          final locations = hub.locations;
          for (final location in locations) {
            netProvider.registerNetwork(networkId);
            final pos = LatLng(location.lat, location.lng);
            if (addedHubs.contains(hubId)) {
              continue;
            }
            addedHubs.add(hubId);
            if (m.user.isMe) {
              bestCameraPos = pos;
            } else {
              bestCameraPos ??= pos;
            }
            final hasRecentEvent = hub.events.isNotEmpty
                ? hub.events[0].createdAt.isAfter(
                    DateTime.fromMillisecondsSinceEpoch(
                      DateTime.now().millisecondsSinceEpoch - (1000 * 3600 * 24 * 7),
                    ),
                  )
                : false;
            print(">>> added marker with networkId: $networkId");
            final iconBytes = await getCustomMarker(
              netProvider.getColorForId(networkId)!,
              hub.name,
              hasRecentEvent,
              netProvider.selectedHub?.hubId == hubId,
            );
            final id = "${m.id}-$hubId";
            final marker = Marker(
              markerId: MarkerId(id),
              position: pos,
              alpha: .7,
              icon: BitmapDescriptor.fromBytes(iconBytes),
              onTap: () {
                final selectedHub = HubObject(hubId, networkId, pos);
                netProvider.setSelectedHub(selectedHub);
              },
            );
            markers.add(marker);
            final fillColor = netProvider.getColorForId(networkId)!.withOpacity(0.2);
            circles.add(Circle(
              circleId: CircleId(id),
              center: pos,
              radius: location.hdop * 2,
              fillColor: fillColor,
              strokeWidth: 0,
            ));
          }
        }
      }
      return markers;
    }

    final Set<Marker> networkMarkers = {};
    Future<bool> loadAllMarkers() async {
      for (var i = 0; i < networks.length; i++) {
        final id = networks[i].id;
        final markers = await getMarkerWidgets(id, i);
        networkMarkers.addAll(markers.toSet());
      }
      return true;
    }

    if (!netProvider.didAnimateToSelection && _mapController != null) {
      netProvider.finishAnimate();
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(netProvider.selectedHub!.loc, 15));
    }

    return Stack(
      children: [
        Column(
          children: [
            TextButton(
              onPressed: () {
                widget.refetch();
              },
              child: const Text("Refresh"),
            ),
            Expanded(
              child: FutureBuilder(
                future: loadAllMarkers(),
                builder: (_, AsyncSnapshot<bool> snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  return GoogleMap(
                    onMapCreated: handleMapCreated,
                    initialCameraPosition: CameraPosition(target: bestCameraPos ?? const LatLng(0, 0), zoom: 12),
                    circles: circles,
                    markers: networkMarkers,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    zoomControlsEnabled: false,
                    buildingsEnabled: false,
                    myLocationEnabled: false,
                    indoorViewEnabled: false,
                    mapToolbarEnabled: false,
                    trafficEnabled: false,
                    onTap: (pos) => netProvider.clearSelectedHub(),
                  );
                },
              ),
            )
          ],
        ),
        if (netProvider.selectedHub != null) NetworkMapDetails(hubObject: netProvider.selectedHub!),
      ],
    );
  }
}
