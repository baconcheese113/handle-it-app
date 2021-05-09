import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/authentication_page.dart';

Future<ValueNotifier<GraphQLClient>> initialize([String newToken]) async {
  final HttpLink httpLink = HttpLink(env['API_URL']);

  final storage = FlutterSecureStorage();
  if (newToken != null) {
    await storage.write(key: 'token', value: newToken);
  }
  final String token = newToken != null ? newToken : await FlutterSecureStorage().read(key: 'token');

  final AuthLink authLink = AuthLink(getToken: () async => "Bearer $token");
  final Link link = authLink.concat(httpLink);

  ValueNotifier<GraphQLClient> client = ValueNotifier(GraphQLClient(
    link: link,
    // The default store is the InMemoryStore, which does NOT persist to disk
    cache: GraphQLCache(store: HiveStore()),
  ));
  return client;
}

class ClientProvider extends StatefulWidget {
  final Widget child;

  ClientProvider({this.child});

  @override
  _ClientProviderState createState() => _ClientProviderState();
}

class _ClientProviderState extends State<ClientProvider> {
  ValueNotifier<GraphQLClient> client;
  bool hasToken = false;

  void initializeClient([String newToken]) async {
    ValueNotifier<GraphQLClient> newClient = await initialize(newToken);
    bool existingToken = await FlutterSecureStorage().containsKey(key: 'token');
    setState(() => {
          hasToken = existingToken,
          client = newClient,
        });
  }

  @override
  void initState() {
    initializeClient();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (this.client == null) {
      return MaterialApp(home: Scaffold(body: Text("Initializing Provider...")));
    }
    return GraphQLProvider(
      client: this.client,
      child: hasToken ? this.widget.child : AuthenticationPage(reinitialize: initializeClient),
    );
  }
}

DocumentNode addFragments(DocumentNode doc, List<DocumentNode> fragments) {
  final newDefinitions = Set<DefinitionNode>.from(doc.definitions);
  for (final frag in fragments) {
    newDefinitions.addAll(frag.definitions);
  }
  return DocumentNode(definitions: newDefinitions.toList(), span: doc.span);
}
