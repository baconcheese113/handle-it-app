import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NetworkMapNotificationOverrides extends StatefulWidget {
  final Map<String, dynamic> hubFrag;
  final Function refetch;
  const NetworkMapNotificationOverrides({Key? key, required this.hubFrag, required this.refetch}) : super(key: key);

  static final fragment = gql(r'''
    fragment networkMapNotificationOverrides_hub on Hub {
      id
      owner {
        isMe
      }
      notificationOverride {
        id
        isMuted
      }
    }
  ''');
  @override
  State<NetworkMapNotificationOverrides> createState() => _NetworkMapNotificationOverridesState();
}

class _NetworkMapNotificationOverridesState extends State<NetworkMapNotificationOverrides> {
  @override
  Widget build(BuildContext context) {
    final bool isMuted = widget.hubFrag['notificationOverride']?['isMuted'] ?? false;
    return Mutation(
        options: MutationOptions(document: gql(r'''
          mutation UpdateNotificationOverride($hubId: Int!, $shouldMute: Boolean!) {
            updateNotificationOverride(hubId: $hubId, shouldMute: $shouldMute) {
              id
              userId
              hubId
              isMuted
              createdAt
            }
          }
        ''')),
        builder: (RunMutation runMutation, QueryResult? result) {
          void handleIconPress() async {
            await runMutation({
              'hubId': widget.hubFrag['id'],
              'shouldMute': !isMuted,
            }).networkResult;
            if (widget.hubFrag['notificationOverride'] == null) await widget.refetch();
          }

          return IconButton(
            onPressed: widget.hubFrag['owner']['isMe'] ? null : handleIconPress,
            icon: Icon(isMuted ? Icons.notifications_off : Icons.notifications_on),
          );
        });
  }
}
