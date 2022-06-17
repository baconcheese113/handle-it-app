import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class NetworkMemberDelete extends StatefulWidget {
  final Map<String, dynamic> memberFrag;
  const NetworkMemberDelete({Key? key, required this.memberFrag}) : super(key: key);

  static final fragment = gql(r'''
    fragment networkMemberDelete_member on NetworkMember {
      id
      user {
        isMe
      }
    }
  ''');

  @override
  State<NetworkMemberDelete> createState() => _NetworkMemberDeleteState();
}

class _NetworkMemberDeleteState extends State<NetworkMemberDelete> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(r'''
        mutation DeleteNetworkMember($networkMemberId: Int!) {
          deleteNetworkMember(networkMemberId: $networkMemberId) {
            id
            members {
              id
            }
          }
        }
      '''),
      ),
      builder: (RunMutation runMutation, QueryResult? result) {
        return IconButton(
          onPressed: () => runMutation({'networkMemberId': widget.memberFrag['id']}),
          icon: const Icon(Icons.delete),
        );
      },
    );
  }
}
