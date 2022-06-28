import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMemberDelete extends StatefulWidget {
  final NetworkMemberDeleteMemberMixin memberFrag;
  const NetworkMemberDelete({Key? key, required this.memberFrag}) : super(key: key);

  @override
  State<NetworkMemberDelete> createState() => _NetworkMemberDeleteState();
}

class _NetworkMemberDeleteState extends State<NetworkMemberDelete> {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: DELETE_NETWORK_MEMBER_MUTATION_DOCUMENT,
        operationName: DELETE_NETWORK_MEMBER_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        return IconButton(
          onPressed: () {
            runMutation(
              DeleteNetworkMemberArguments(
                networkMemberId: widget.memberFrag.id,
              ).toJson(),
            );
          },
          icon: const Icon(Icons.delete),
        );
      },
    );
  }
}
