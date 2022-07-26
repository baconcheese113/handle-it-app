import 'dart:math';

import 'package:flutter/material.dart';
import 'package:handle_it/feed/~graphql/__generated__/feed_home.query.graphql.dart';
import 'package:handle_it/settings/~graphql/__generated__/add_test_hub.mutation.graphql.dart';
import 'package:handle_it/settings/~graphql/__generated__/settings.fragments.graphql.dart';

class AddTestHub extends StatefulWidget {
  final Fragment$addTestHub_user user;
  const AddTestHub({Key? key, required this.user}) : super(key: key);

  @override
  State<AddTestHub> createState() => _AddTestHubState();
}

class _AddTestHubState extends State<AddTestHub> {
  String _name = "";
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Mutation$AddTestHub$Widget(
      options: WidgetOptions$Mutation$AddTestHub(
        update: (cache, result) {
          if (result?.data == null) return;
          final newHub = result!.parsedData!.createHub!;
          final request = Options$Query$FeedHome().asRequest;
          final readQuery = cache.readQuery(request);
          if (readQuery == null) return;
          final map = Query$FeedHome.fromJson(readQuery);
          final hubs = map.viewer.user.hubs;
          hubs.add(Query$FeedHome$viewer$user$hubs.fromJson(newHub.toJson()));
          cache.writeQuery(request, data: map.toJson(), broadcast: true);
        },
      ),
      builder: (runMutation, result) {
        void commitChange() async {
          final random = Random().nextInt(1000);
          await runMutation(
            Variables$Mutation$AddTestHub(
              name: _name,
              serial: 'testSerial$random',
              imei: 'testImei$random',
            ),
          ).networkResult;
          if (!result!.hasException && result.isNotLoading) {
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
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _name.isNotEmpty ? commitChange : null,
                child: const Text("Create Test Hub"),
              ),
            ],
          ),
        );
      },
    );
  }
}
