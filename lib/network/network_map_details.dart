import 'package:flutter/material.dart';
import 'package:handle_it/network/network_provider.dart';
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
    final fixedAt = timeago.format(DateTime.parse(widget.hubObject.fixedAt));
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
                  child: Text(widget.hubObject.hubName),
                ),
                Chip(
                    label: Text(widget.hubObject.networkName, style: const TextStyle(fontSize: 12)),
                    backgroundColor: widget.hubObject.hue),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(widget.hubObject.memberEmail), Text("As of $fixedAt")],
            ),
            trailing: IconButton(
                onPressed: handleIconPress, icon: Icon(_isMuted ? Icons.notifications_off : Icons.notifications_on)),
          ),
        ),
      ),
    );
  }
}
