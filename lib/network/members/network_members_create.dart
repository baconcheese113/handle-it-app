import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NetworkMembersCreate extends StatefulWidget {
  final Map<String, dynamic> networkFrag;
  const NetworkMembersCreate({Key? key, required this.networkFrag}) : super(key: key);

  static final networkMembersCreateFragment = gql(r'''
    fragment networkMembersCreate_network on Network {
      id
      members {
        id
        user {
          email
        }
      }
    }
  ''');

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
      options: MutationOptions(document: gql(r'''
          mutation CreateNetworkMember($networkId: Int!, $email: String!, $role: RoleType!) {
            createNetworkMember(networkId: $networkId, email: $email, role: $role) {
              id
              role
              userId
              user {
                email
              }
              networkId
              network {
                name
                members {
                  id
                }
              }
            }
          }
        ''')),
      builder: (RunMutation runMutation, QueryResult? result) {
        void handleCreate() async {
          final mutation = await runMutation({
            'networkId': widget.networkFrag['id'],
            'email': _newEmail,
            'role': "member",
          }).networkResult;

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
                controller: _controller,
                decoration: const InputDecoration(hintText: "Enter new member email"),
                onChanged: (newText) => setState(() => _newEmail = newText),
              ),
            ),
            IconButton(onPressed: canAdd ? handleCreate : null, icon: const Icon(Icons.add)),
          ],
        );
      },
    );
  }
}
