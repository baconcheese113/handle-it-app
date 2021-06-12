import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedCardArm extends StatefulWidget {
  final hub;
  const FeedCardArm({Key key, this.hub}) : super(key: key);

  static final feedCardArmFragment = gql(r'''
    fragment feedCardArm_hub on Hub {
      id
      isArmed
    }
    ''');

  @override
  _FeedCardArmState createState() => _FeedCardArmState();
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
        QueryResult result,
      ) {
        bool isArmed = this.widget.hub['isArmed'];
        return TextButton(
            onPressed: () async {
              await runMutation({'id': this.widget.hub['id'], 'isArmed': !isArmed}).networkResult;
            },
            child: Text(isArmed ? "Disarm" : "Arm"));
      },
    );
  }
}
