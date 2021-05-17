import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_card.dart';
import 'package:handle_it/utils.dart';

class AddTestHub extends StatefulWidget {
  final user;
  const AddTestHub({Key key, this.user}) : super(key: key);

  static final addTestHubFragment = gql(r"""
    fragment addTestHubFragment_user on User {
      id
    }
  """);

  @override
  _AddTestHubState createState() => _AddTestHubState();
}

class _AddTestHubState extends State<AddTestHub> {
  String _name = "";
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (this.widget.user['id'] == null) return null;
    return Mutation(
      options: MutationOptions(document: addFragments(gql(r'''
          mutation createOneHub($data: HubCreateInput!) {
            createOneHub(data: $data) {
              id
              ...feedCardFragment_hub
            }
          }
        '''), [FeedCard.feedCardFragment])),
      builder: (
        RunMutation runMutation,
        QueryResult result,
      ) {
        void commitChange() async {
          final result = await runMutation({
            'data': {
              'name': _name,
              'serial': "testSerial",
              'owner': {
                'connect': {'id': this.widget.user['id']}
              }
            }
          }).networkResult;
          if (!result.hasException && !result.isLoading) {
            setState(() => _name = "");
            _controller.clear();
          }
        }

        return Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controller,
                onChanged: (newValue) => setState(() => _name = newValue),
                decoration: InputDecoration(
                  hintText: 'Enter Hub name',
                  suffixIcon: IconButton(
                    onPressed: () => _controller.clear(),
                    icon: Icon(Icons.clear),
                  ),
                ),
              ),
              ElevatedButton(onPressed: _name.isNotEmpty ? commitChange : null, child: const Text("Create Test Hub")),
            ],
          ),
        );
      },
    );
  }
}
