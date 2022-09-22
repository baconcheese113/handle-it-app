import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:handle_it/graphql/__generated__/schema.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/members.fragments.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_create.mutation.graphql.dart';
import 'package:handle_it/network/members/~graphql/__generated__/network_members_tab.query.graphql.dart';

class NetworkMembersCreate extends StatefulWidget {
  final Fragment$networkMembersCreate_network networkFrag;
  const NetworkMembersCreate({Key? key, required this.networkFrag}) : super(key: key);

  @override
  State<NetworkMembersCreate> createState() => _NetworkMembersCreateState();
}

class _NetworkMembersCreateState extends State<NetworkMembersCreate> {
  String _newEmail = "";
  final TextEditingController _controller = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    return Mutation$CreateNetworkMember$Widget(
      options: WidgetOptions$Mutation$CreateNetworkMember(
        update: (cache, result) {
          if (result?.data == null) return;
          final newMember = result!.parsedData!.createNetworkMember;
          final request = Options$Query$NetworkMembersTab().asRequest;
          final readQuery = cache.readQuery(request);
          if (readQuery == null) return;
          final map = Query$NetworkMembersTab.fromJson(readQuery);
          final network = map.viewer.networks.firstWhere((n) => n.id == newMember.network.id);
          network.members.add(Query$NetworkMembersTab$viewer$networks$members.fromJson(newMember.toJson()));
          cache.writeQuery(request, data: map.toJson(), broadcast: true);
        },
      ),
      builder: (runMutation, result) {
        void handleCreate() async {
          FocusManager.instance.primaryFocus?.unfocus();
          final mutation = await runMutation(
            Variables$Mutation$CreateNetworkMember(
              networkId: widget.networkFrag.id,
              email: _newEmail,
              role: Enum$RoleType.member,
            ),
          ).networkResult;

          if (mutation != null && !mutation.hasException && mutation.isNotLoading) {
            _controller.clear();
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
