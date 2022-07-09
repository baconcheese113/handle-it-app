import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class AddTestHub extends StatefulWidget {
  final AddTestHubUserMixin user;
  const AddTestHub({Key? key, required this.user}) : super(key: key);

  @override
  State<AddTestHub> createState() => _AddTestHubState();
}

class _AddTestHubState extends State<AddTestHub> {
  String _name = "";
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: ADD_TEST_HUB_MUTATION_DOCUMENT,
        operationName: ADD_TEST_HUB_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        void commitChange() async {
          final random = Random().nextInt(1000);
          await runMutation(
            AddTestHubArguments(
              name: _name,
              serial: 'testSerial$random',
              imei: 'testImei$random',
            ).toJson(),
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
