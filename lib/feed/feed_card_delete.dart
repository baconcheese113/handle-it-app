import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class FeedCardDelete extends StatefulWidget {
  final Map<String, dynamic> hub;
  final Function onDelete;
  const FeedCardDelete({Key? key, required this.hub, required this.onDelete}) : super(key: key);

  @override
  State<FeedCardDelete> createState() => _FeedCardDeleteState();
}

class _FeedCardDeleteState extends State<FeedCardDelete> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(document: addFragments(gql(r'''
        mutation feedCardDeleteMutation($id: ID!) {
          deleteHub(id: $id) {
            id
            ...feedCard_hub
          }
        }
      '''), [FeedCard.feedCardFragment])),
      builder: (
        RunMutation runMutation,
        QueryResult? result,
      ) {
        return TextButton(
            onPressed: () async {
              await runMutation({'id': widget.hub['id']}).networkResult;
              widget.onDelete();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ));
      },
    );
  }
}
