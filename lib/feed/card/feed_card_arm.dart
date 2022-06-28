import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class FeedCardArm extends StatefulWidget {
  final FeedCardArmHubMixin hubFrag;
  const FeedCardArm({Key? key, required this.hubFrag}) : super(key: key);

  @override
  State<FeedCardArm> createState() => _FeedCardArmState();
}

class _FeedCardArmState extends State<FeedCardArm> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
        options: MutationOptions(
          document: FEED_CARD_ARM_MUTATION_DOCUMENT,
          operationName: FEED_CARD_ARM_MUTATION_DOCUMENT_OPERATION_NAME,
        ),
        builder: (runMutation, result) {
          bool isArmed = widget.hubFrag.isArmed;
          handleArmSwitch(newState) async {
            await runMutation(
              FeedCardArmArguments(
                id: "${widget.hubFrag.id}",
                isArmed: !isArmed,
              ).toJson(),
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
