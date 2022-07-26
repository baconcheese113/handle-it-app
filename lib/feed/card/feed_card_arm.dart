import 'package:flutter/material.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card.fragments.graphql.dart';
import 'package:handle_it/feed/card/~graphql/__generated__/feed_card_arm.mutation.graphql.dart';

class FeedCardArm extends StatelessWidget {
  final Fragment$feedCardArm_hub hubFrag;
  const FeedCardArm({Key? key, required this.hubFrag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation$feedCardArm$Widget(builder: (runMutation, result) {
      bool isArmed = hubFrag.isArmed;
      handleArmSwitch(newState) async {
        await runMutation(
          Variables$Mutation$feedCardArm(
            id: "${hubFrag.id}",
            isArmed: !isArmed,
          ),
        ).networkResult;
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
