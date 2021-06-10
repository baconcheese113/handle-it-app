import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedCardDelete extends StatefulWidget {
  final hub;
  final Function onDelete;
  const FeedCardDelete({Key key, this.hub, this.onDelete}) : super(key: key);

  @override
  _FeedCardDeleteState createState() => _FeedCardDeleteState();
}

class _FeedCardDeleteState extends State<FeedCardDelete> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(document: addFragments(gql(r'''
        mutation feedCardDeleteMutation($id: ID!) {
          deleteHub(id: $id) {
            id
            ...feedCardFragment_hub
          }
        }
      '''), [FeedCard.feedCardFragment])),
      builder: (
        RunMutation runMutation,
        QueryResult result,
      ) {
        return TextButton(
            onPressed: () async {
              await runMutation({'id': this.widget.hub['id']}).networkResult;
              this.widget.onDelete();
            },
            child: Text("Delete"));
      },
    );
  }
}
