import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMembersCreate extends StatefulWidget {
  final NetworkMembersCreateNetworkMixin networkFrag;
  const NetworkMembersCreate({Key? key, required this.networkFrag}) : super(key: key);

  @override
  State<NetworkMembersCreate> createState() => _NetworkMembersCreateState();
}

class _NetworkMembersCreateState extends State<NetworkMembersCreate> {
  String _newEmail = "";
  final TextEditingController _controller = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    onSubmitEnd(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Mutation(
      options: MutationOptions(
        document: CREATE_NETWORK_MEMBER_MUTATION_DOCUMENT,
        operationName: CREATE_NETWORK_MEMBER_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        void handleCreate() async {
          final mutation = await runMutation(
            CreateNetworkMemberArguments(
              networkId: widget.networkFrag.id,
              email: _newEmail,
              role: RoleType.member,
            ).toJson(),
          ).networkResult;

          if (mutation != null && !mutation.hasException && mutation.isNotLoading) {
            _controller.clear();
            // TODO avoid needing to refresh manually
            onSubmitEnd("User added, refresh to view");
          }
        }

        final canAdd = _newEmail.isNotEmpty && EmailValidator.validate(_newEmail);

        return Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('input.newMember'),
                controller: _controller,
                decoration: const InputDecoration(hintText: "Enter new member email"),
                onChanged: (newText) => setState(() => _newEmail = newText),
              ),
            ),
            IconButton(
              key: const ValueKey('button.newMember'),
              onPressed: canAdd ? handleCreate : null,
              icon: const Icon(Icons.add),
            ),
          ],
        );
      },
    );
  }
}
