import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'network_map_notification_overrides.dart';

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
    final query = NetworkMapDetailsQuery(variables: NetworkMapDetailsArguments(hubId: hubId));
    return Query(
      options: QueryOptions(
        document: query.document,
        operationName: query.operationName,
        variables: query.variables.toJson(),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final hub = query.parse(result.data!).hub;
        final networks = hub?.networks;
        final network = networks?.firstWhereOrNull((n) => n.id == networkId);
        if (network == null) return const SizedBox();
        final events = hub!.events;
        final String notifStr = () {
          final notifOverride = hub.notificationOverride;
          if (notifOverride == null || !notifOverride.isMuted) return "Default";
          return "Muted";
        }();
        final fixedAt = timeago.format(hub.locations[0].fixedAt!);
        Chip getChipFromNetwork(NetworkMapDetails$Query$Hub$Networks n) {
          return Chip(
            label: Text(n.name, style: const TextStyle(fontSize: 10)),
            backgroundColor: netProvider.registerNetwork(n.id),
          );
        }

        networks!.removeWhere((n) => n.id == networkId);
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
                                    child: Text(hub.name),
                                  ),
                                  getChipFromNetwork(network),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hub.owner.email),
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
                                        DataCell(Text(timeago.format(event.createdAt))),
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
