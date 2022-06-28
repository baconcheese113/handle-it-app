import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMapNotificationOverrides extends StatefulWidget {
  final NetworkMapNotificationOverridesHubMixin hubFrag;
  final Function refetch;
  const NetworkMapNotificationOverrides({Key? key, required this.hubFrag, required this.refetch}) : super(key: key);

  @override
  State<NetworkMapNotificationOverrides> createState() => _NetworkMapNotificationOverridesState();
}

class _NetworkMapNotificationOverridesState extends State<NetworkMapNotificationOverrides> {
  @override
  Widget build(BuildContext context) {
    final bool isMuted = widget.hubFrag.hubNotifications?.isMuted ?? false;
    return Mutation(
        options: MutationOptions(
          document: UPDATE_NOTIFICATION_OVERRIDE_MUTATION_DOCUMENT,
          operationName: UPDATE_NOTIFICATION_OVERRIDE_MUTATION_DOCUMENT_OPERATION_NAME,
        ),
        builder: (runMutation, result) {
          void handleIconPress() async {
            await runMutation(
              UpdateNotificationOverrideArguments(
                hubId: widget.hubFrag.id,
                shouldMute: !isMuted,
              ).toJson(),
            ).networkResult;
            if (widget.hubFrag.hubNotifications == null) await widget.refetch();
          }

          return IconButton(
            onPressed: widget.hubFrag.hubOwner.isMe ? null : handleIconPress,
            icon: Icon(isMuted ? Icons.notifications_off : Icons.notifications_on),
          );
        });
  }
}
