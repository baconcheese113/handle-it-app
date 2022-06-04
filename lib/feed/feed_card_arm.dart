import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedCardArm extends StatefulWidget {
  final Map<String, dynamic> hub;
  const FeedCardArm({Key? key, required this.hub}) : super(key: key);

  static final feedCardArmFragment = gql(r'''
    fragment feedCardArm_hub on Hub {
      id
      isArmed
    }
    ''');

  @override
  State<FeedCardArm> createState() => _FeedCardArmState();
}

class _FeedCardArmState extends State<FeedCardArm> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
        options: MutationOptions(document: addFragments(gql(r'''
        mutation feedCardArmMutation($id: ID!, $isArmed: Boolean!) {
          updateHub(id: $id, isArmed: $isArmed) {
            id
            ...feedCard_hub
          }
        }
      '''), [FeedCard.feedCardFragment])),
        builder: (
          RunMutation runMutation,
          QueryResult? result,
        ) {
          bool isArmed = widget.hub['isArmed'];
          handleArmSwitch(newState) async {
            await runMutation({'id': widget.hub['id'], 'isArmed': !isArmed}).networkResult;
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: ColoredBox(
              color: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(isArmed ? "Armed" : "Disarmed"),
                  Switch(value: isArmed, onChanged: handleArmSwitch),
                ]),
              ),
            ),
          );
        });
  }
}
