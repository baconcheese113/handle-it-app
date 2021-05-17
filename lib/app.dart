import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/auth/register.dart';
import 'package:handle_it/feed/add_vehicle_wizard.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/notifications/show_alert.dart';
import 'package:rxdart/subjects.dart';

class AuthenticationState extends ChangeNotifier {
  String token;
  bool loading = true;
  final storage = FlutterSecureStorage();

  Future<void> checkForExistingToken() async {
    loading = true;
    print("Looking for existing token");
    if (await storage.containsKey(key: 'token')) {
      token = await storage.read(key: 'token');
      print("Token found $token");
    }
    loading = false;
    notifyListeners();
  }

  ValueNotifier<GraphQLClient> getClient() {
    final HttpLink httpLink = HttpLink(env['API_URL']);
    final AuthLink authLink = AuthLink(getToken: () => token != null ? "Bearer $token" : null);
    final link = authLink.concat(httpLink);
    return ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: link,
      ),
    );
  }
}

class App extends StatefulWidget {
  final String initialRoute;
  final BehaviorSubject<String> selectNotificationSubject;
  App({Key key, this.initialRoute, this.selectNotificationSubject}) : super(key: key);

  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool isLoading = true;
  BleManager _bleManager;
  AuthenticationState authenticationState;

  void listenForAuthStateChanges() {
    print(
        "authenticationState listener triggered with loading: ${authenticationState.loading}, isLoading = $isLoading");
    if (isLoading != authenticationState.loading) setState(() => isLoading = authenticationState.loading);
  }

  @override
  void initState() {
    super.initState();
    authenticationState = AuthenticationState();
    isLoading = true;
    authenticationState.addListener(listenForAuthStateChanges);
    authenticationState.checkForExistingToken();
    print("app: init state");
    this.widget.selectNotificationSubject.stream.listen((String payload) async {
      print("heard $payload from the stream");
      await this.widget._navigator.currentState.pushNamed(ShowAlert.routeName);
    });

    _bleManager = BleManager();
    _bleManager?.createClient();
  }

  @override
  void dispose() {
    print("disposing");
    isLoading = true;
    this.widget.selectNotificationSubject.close();
    authenticationState.removeListener(listenForAuthStateChanges);
    _bleManager?.destroyClient();
    super.dispose();
  }

  void reinitialize([String newToken]) {
    authenticationState.token = newToken;
  }

  @override
  Widget build(BuildContext context) {
    String initialRoute = this.widget.initialRoute;

    final client = authenticationState.getClient();

    print("Rendering authenticationState.loading ${authenticationState.loading}");
    print("Initialroute = $initialRoute");
    if (initialRoute != ShowAlert.routeName && (authenticationState.loading || isLoading)) {
      return Directionality(textDirection: TextDirection.ltr, child: Text("Checking for token..."));
    }
    if (initialRoute != ShowAlert.routeName && authenticationState.token != null) {
      initialRoute = Home.routeName;
    }
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'HandleIt',
        initialRoute: initialRoute,
        navigatorKey: this.widget._navigator,
        routes: <String, WidgetBuilder>{
          Home.routeName: (_) => Home(reinitialize: reinitialize),
          ShowAlert.routeName: (_) => ShowAlert(),
          Register.routeName: (_) => Register(reinitialize: reinitialize),
          Login.routeName: (_) => Login(reinitialize: reinitialize),
          AddVehicleWizard.routeName: (_) => AddVehicleWizard(bleManager: _bleManager),
        },
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
      ),
    );
  }
}
