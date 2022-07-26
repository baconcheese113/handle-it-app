import 'package:flutter/material.dart';
import 'package:handle_it/network/map/~graphql/__generated__/map.fragments.graphql.dart';
import 'package:handle_it/network/map/~graphql/__generated__/network_map_notification_overrides.mutation.graphql.dart';

class NetworkMapNotificationOverrides extends StatelessWidget {
  final Fragment$networkMapNotificationOverrides_hub hubFrag;
  final Function refetch;
  const NetworkMapNotificationOverrides({Key? key, required this.hubFrag, required this.refetch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMuted = hubFrag.notificationOverride?.isMuted ?? false;
    return Mutation$UpdateNotificationOverride$Widget(
      builder: (runMutation, result) {
        void handleIconPress() async {
          await runMutation(
            Variables$Mutation$UpdateNotificationOverride(
              hubId: hubFrag.id,
              shouldMute: !isMuted,
            ),
          ).networkResult;
          if (hubFrag.notificationOverride == null) await refetch();
        }

        return IconButton(
          onPressed: hubFrag.owner.isMe ? null : handleIconPress,
          icon: Icon(isMuted ? Icons.notifications_off : Icons.notifications_on),
        );
      },
    );
  }
}
