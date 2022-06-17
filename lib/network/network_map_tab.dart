import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_map_details.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:provider/provider.dart';

class NetworkMapTab extends StatefulWidget {
  final Map<String, dynamic> viewerFrag;
  final Function refetch;
  const NetworkMapTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  static final fragment = gql(r'''
    fragment networkMapTab_viewer on Viewer {
      activeNetworks: networks (status: active) {
        id
        name
        createdById
        members {
          status
          role
          user {
            id
            isMe
            email
            hubs {
              id
              name
              locations(last: 1) {
                lat
                lng
                fixedAt
              }
            }
          }
        }
      }
    }
  ''');

  @override
  State<NetworkMapTab> createState() => _NetworkMapTabState();
}

class _NetworkMapTabState extends State<NetworkMapTab> {
  GoogleMapController? _mapController;

  void handleMapCreated(GoogleMapController mapController) {
    setState(() => _mapController = mapController);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final netProvider = Provider.of<NetworkProvider>(context);
    final List<dynamic> networks = widget.viewerFrag['networks'];
    final List<int> addedHubs = [];
    LatLng? bestCameraPos;

    List<Marker> getMarkerWidgets(int networkId, int idx) {
      final network = networks.firstWhere((n) => n['id'] == networkId);
      final List<dynamic> members = network['members'];
      final List<Marker> markers = [];
      for (final m in members) {
        final List<dynamic> hubs = m['user']['hubs'];
        for (final hub in hubs) {
          final int hubId = hub['id'];
          final List<dynamic> locations = hub['locations'];
          for (final location in locations) {
            netProvider.registerNetwork(networkId);
            final pos = LatLng(location['lat'], location['lng']);
            if (addedHubs.contains(hubId)) {
              continue;
            }
            addedHubs.add(hubId);
            if (m['user']['isMe']) {
              bestCameraPos = pos;
            } else {
              bestCameraPos ??= pos;
            }
            print(">>> added marker with networkId: $networkId");
            final marker = Marker(
              markerId: MarkerId("${m['id']}-$hubId"),
              position: pos,
              alpha: .7,
              icon: BitmapDescriptor.defaultMarkerWithHue(netProvider.getMarkerHue(networkId)),
              onTap: () {
                final selectedHub = HubObject(hubId, networkId, pos);
                netProvider.setSelectedHub(selectedHub);
              },
            );
            markers.add(marker);
          }
        }
      }
      return markers;
    }

    final Set<Marker> networkMarkers = {};
    for (var i = 0; i < networks.length; i++) {
      int id = networks[i]['id'];
      networkMarkers.addAll(getMarkerWidgets(id, i).toSet());
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
              child: GoogleMap(
                onMapCreated: handleMapCreated,
                initialCameraPosition: CameraPosition(target: bestCameraPos ?? const LatLng(0, 0), zoom: 12),
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
              ),
            )
          ],
        ),
        if (netProvider.selectedHub != null) NetworkMapDetails(hubObject: netProvider.selectedHub!),
      ],
    );
  }
}
