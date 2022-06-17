import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_map_notification_overrides.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

final List<Map<String, Color>> carColors = [
  {"Silver": Colors.white60},
  {"White": Colors.white},
  {"Red": Colors.red},
  {"Blue": Colors.blue},
  {"Brown": Colors.brown}
];

class NetworkMapDetails extends StatefulWidget {
  final HubObject hubObject;
  const NetworkMapDetails({Key? key, required this.hubObject}) : super(key: key);

  @override
  State<NetworkMapDetails> createState() => _NetworkMapDetailsState();
}

class _NetworkMapDetailsState extends State<NetworkMapDetails> {
  bool _isMuted = false;
  handleIconPress() {
    setState(() => _isMuted = !_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    final netProvider = Provider.of<NetworkProvider>(context, listen: false);
    final hubId = widget.hubObject.hubId;
    final networkId = widget.hubObject.networkId;
    return Query(
      options: QueryOptions(
        document: addFragments(gql(r'''
        query networkMapDetailsQuery($hubId: Int!) {
          hub(id: $hubId) {
            name
            owner {
              isMe
              email
            }
            locations(last: 1) {
              fixedAt
            }
            events {
              id
              createdAt
            }
            networks {
              id
              name
            }
            notificationOverride {
              id
              isMuted
              createdAt
            }
            ...networkMapNotificationOverrides_hub
          }
        }
      '''), [NetworkMapNotificationOverrides.fragment]),
        variables: {"hubId": hubId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.data == null && result.isLoading) return const SizedBox();
        if (result.hasException) return Center(child: Text(result.exception.toString()));
        final hub = result.data!['hub'];
        final List<dynamic> networks = hub['networks'];
        print(">>> looking for $hubId and networks are $networks");
        if (!networks.any((n) => n['id'] == networkId)) return const SizedBox();
        final network = networks.firstWhere((n) => n['id'] == networkId);
        final List<dynamic> events = hub['events'];
        final String notifStr = () {
          final notifOverride = hub['notificationOverride'];
          if (notifOverride == null || !notifOverride['isMuted']) return "Default";
          return "Muted";
        }();
        final fixedAt = timeago.format(DateTime.parse(hub['locations'][0]['fixedAt']));
        getChipFromNetwork(Map<String, dynamic> n) {
          return Chip(
            label: Text(n['name'], style: const TextStyle(fontSize: 10)),
            backgroundColor: netProvider.registerNetwork(n['id']),
          );
        }

        networks.removeWhere((n) => n['id'] == networkId);
        final networkChips = networks.map((n) => getChipFromNetwork(n));
        const minSize = .2;
        const maxSize = .8;
        final colorMap = carColors[hubId % carColors.length];

        return DraggableScrollableSheet(
          initialChildSize: minSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          snap: true,
          snapSizes: const [minSize, maxSize],
          builder: (context, scrollController) {
            return ColoredBox(
              color: Colors.black,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 0,
                          left: 50,
                          right: 50,
                          height: 1,
                          child: ColoredBox(color: Colors.white),
                        ),
                        Column(
                          children: [
                            ListTile(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Text(hub['name']),
                                  ),
                                  getChipFromNetwork(network),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hub['owner']['email']),
                                  Text("As of $fixedAt"),
                                  if (networkChips.isNotEmpty)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [const Text("Also in "), ...networkChips],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: NetworkMapNotificationOverrides(hubFrag: hub, refetch: refetch!),
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              Column(children: [
                                Text("Notifications: $notifStr"),
                                const Text("Make: Unknown"),
                                const Text("Model: Unknown"),
                                Text("Color: ${colorMap.keys.first}"),
                              ]),
                              Icon(Icons.directions_car, size: 128, color: colorMap.values.first),
                            ]),
                            events.isNotEmpty
                                ? DataTable(
                                    columns: const [
                                      DataColumn(label: Text("Time")),
                                      DataColumn(label: Text("Event")),
                                    ],
                                    rows: events.map((event) {
                                      return DataRow(cells: [
                                        DataCell(Text(timeago.format(DateTime.parse(event['createdAt'])))),
                                        const DataCell(Text("Handle pulled")),
                                      ]);
                                    }).toList(),
                                  )
                                : const Text("No events have been sent yet"),
                          ],
                        ),
                      ],
                    )),
              ),
            );
          },
        );
      },
    );
  }
}
