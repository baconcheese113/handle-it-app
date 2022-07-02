import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/__generated__/api.graphql.dart';

class NetworkMemberAccept extends StatelessWidget {
  final int memberId;
  const NetworkMemberAccept({Key? key, required this.memberId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: ACCEPT_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT,
        operationName: ACCEPT_NETWORK_MEMBERSHIP_MUTATION_DOCUMENT_OPERATION_NAME,
      ),
      builder: (runMutation, result) {
        return IconButton(
          onPressed: () {
            runMutation(
              AcceptNetworkMembershipArguments(
                networkMemberId: memberId,
              ).toJson(),
            );
          },
          icon: const Icon(Icons.check_circle),
        );
      },
    );
  }
}
