import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/network/network_map_notification_overrides.dart';
import 'package:handle_it/network/network_provider.dart';
import 'package:handle_it/utils.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    final netProvider = Provider.of<NetworkProvider>(context);
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
            networks {
              id
              name
            }
            ...networkMapNotificationOverrides_hub
          }
        }
      '''), [NetworkMapNotificationOverrides.fragment]),
        variables: {"hubId": widget.hubObject.hubId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const SizedBox();
        if (result.hasException) return const Center(child: Text("Failed to load"));
        final hub = result.data!['hub'];
        final List<dynamic> networks = hub['networks'];
        print(">>> looking for ${widget.hubObject.hubId} and networks are $networks");
        final network = networks.firstWhere((n) => n['id'] == widget.hubObject.networkId);
        final fixedAt = timeago.format(DateTime.parse(hub['locations'][0]['fixedAt']));
        getChipFromNetwork(Map<String, dynamic> n) {
          return Chip(
            label: Text(n['name'], style: const TextStyle(fontSize: 10)),
            backgroundColor: netProvider.registerNetwork(n['id']),
          );
        }

        networks.removeWhere((n) => n['id'] == widget.hubObject.networkId);
        final networkChips = networks.map((n) => getChipFromNetwork(n));

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Row(
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
                      Row(
                        children: [const Text("Also in "), ...networkChips],
                      )
                  ],
                ),
                trailing: NetworkMapNotificationOverrides(hubFrag: hub, refetch: refetch!),
              ),
            ),
          ),
        );
      },
    );
  }
}
