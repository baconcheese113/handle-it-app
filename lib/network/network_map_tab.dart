import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NetworkMapTab extends StatefulWidget {
  final Map<String, dynamic> viewerFrag;
  final Function refetch;
  const NetworkMapTab({Key? key, required this.viewerFrag, required this.refetch}) : super(key: key);

  static final networkMapTabFragment = gql(r'''
    fragment networkMapTab_viewer on Viewer {
      user {
        id
      }
      networks {
        id
        name
        createdById
        members {
          status
          role
          user {
            id
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
  @override
  Widget build(BuildContext context) {
    final List<dynamic> networks = widget.viewerFrag['networks'];
    final int thisUserId = widget.viewerFrag['user']['id'];
    print(">>> thisUserId is $thisUserId and Networks are $networks");

    const hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueAzure,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueCyan,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueMagenta,
      BitmapDescriptor.hueRose,
      BitmapDescriptor.hueViolet,
    ];

    List<Marker> getMarkerWidgets(int networkId, int idx) {
      print(">>> getMarkerWidgets() for $networkId at idx $idx");
      final network = networks.firstWhere((n) => n['id'] == networkId);
      final List<dynamic> members = network['members'];
      final List<Marker> markers = [];
      for (final m in members) {
        if (m['status'] != 'active' || m['user']['id'] == thisUserId) continue;
        final List<dynamic> hubs = m['user']['hubs'];
        for (final hub in hubs) {
          final int hubId = hub['id'];
          final List<dynamic> locations = hub['locations'];
          for (final location in locations) {
            print(">>> location $location");
            final pos = LatLng(location['lat'], location['lng']);
            print(">>> adding hub $hubId at location $pos");
            final marker = Marker(
              markerId: MarkerId("${m['id']}-$hubId"),
              position: pos,
              alpha: .7,
              icon: BitmapDescriptor.defaultMarkerWithHue(hues[idx]),
              infoWindow: InfoWindow(
                title: hub['name'],
                snippet: "As of ${timeago.format(DateTime.parse(location['fixedAt']))}",
              ),
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

    return Column(
      children: [
        SizedBox(
            height: 100,
            child: TextButton(
                onPressed: () {
                  widget.refetch();
                },
                child: const Text("Refresh"))),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(39.7, -104.76), zoom: 10),
            markers: networkMarkers,
          ),
        )
      ],
    );
  }
}
