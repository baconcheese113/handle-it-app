import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/auth/register.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/notifications/show_alert.dart';
import 'package:rxdart/subjects.dart';

class AuthenticationState extends ChangeNotifier {
  String token;
  bool loading = true;
  final storage = FlutterSecureStorage();

  AuthenticationState() {
    checkForExistingToken();
  }

  Future<void> checkForExistingToken() async {
    loading = true;
    if (await storage.containsKey(key: 'token')) {
      authenticate(await storage.read(key: 'token'));
    } else {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> authenticate(String newToken) async {
    loading = true;
    await storage.write(key: 'token', value: newToken);
    token = newToken;
    loading = false;
    notifyListeners();
  }

  Future<void> invalidate() async {
    loading = true;
    await storage.delete(key: 'token');
    token = null;
    loading = false;
    notifyListeners();
  }
}

class App extends StatefulWidget {
  final String initialRoute;
  final BehaviorSubject<String> selectNotificationSubject;
  App({Key key, this.initialRoute, this.selectNotificationSubject}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final AuthenticationState authenticationState = AuthenticationState();

  @override
  void initState() {
    super.initState();
    this.widget.selectNotificationSubject.stream.listen((String payload) async {
      print("heard $payload from the stream");
      await Navigator.pushNamed(context, ShowAlert.routeName);
    });
    authenticationState.checkForExistingToken();
  }

  @override
  void dispose() {
    this.widget.selectNotificationSubject.close();
    super.dispose();
  }

  void reinitialize([String newToken]) async {
    print("Reinitializing with $newToken");
    if (newToken == null) {
      await authenticationState.invalidate();
      return;
    }
    await authenticationState.authenticate(newToken);
  }

  @override
  Widget build(BuildContext context) {
    // final AuthenticationState authenticationState = Provider.of<AuthenticationState>(context);
    final HttpLink httpLink = HttpLink(env['API_URL']);
    Link link = httpLink;
    if (authenticationState.token != null) {
      final AuthLink authLink = AuthLink(getToken: () {
        print("Creating authLink in getToken with ${authenticationState.token}");
        return "Bearer ${authenticationState.token}";
      });
      // final AuthLink authLink = AuthLink(getToken: () => "Bearer ${authenticationState.token}");
      link = authLink.concat(httpLink);
    }
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: link,
      ),
    );
    print("Rendering authenticationState.loading ${authenticationState.loading}");
    if (authenticationState.loading) {
      return Directionality(textDirection: TextDirection.ltr, child: Text("Checking for token..."));
    }

    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'HandleIt',
        initialRoute: this.widget.initialRoute,
        routes: <String, WidgetBuilder>{
          Home.routeName: (_) => Home(),
          ShowAlert.routeName: (_) => ShowAlert(),
          Register.routeName: (_) => Register(reinitialize: reinitialize),
          Login.routeName: (_) => Login(reinitialize: reinitialize),
        },
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
      ),
    );
  }
}
