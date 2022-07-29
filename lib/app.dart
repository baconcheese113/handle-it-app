import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/auth/login.dart';
import 'package:handle_it/auth/register.dart';
import 'package:handle_it/feed/add_wizards/add_sensor_wizard.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/notifications/show_alert.dart';
import 'package:handle_it/utils.dart';
import 'package:rxdart/subjects.dart';
import 'package:vrouter/vrouter.dart';

import 'feed/add_wizards/add_vehicle_wizard.dart';

class AuthenticationState extends ChangeNotifier {
  String? token;
  bool loading = true;
  final storage = const FlutterSecureStorage();

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
    final HttpLink httpLink = HttpLink(dotenv.env['API_URL']!);
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
  final BehaviorSubject<String>? selectNotificationSubject;
  final String? eventId;
  App({Key? key, required this.initialRoute, this.selectNotificationSubject, this.eventId}) : super(key: key);

  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isLoading = true;
  AuthenticationState authenticationState = AuthenticationState();

  void listenForAuthStateChanges() {
    print(
        "authenticationState listener triggered with loading: ${authenticationState.loading}, isLoading = $isLoading");
    if (isLoading != authenticationState.loading) setState(() => isLoading = authenticationState.loading);
  }

  @override
  void initState() {
    super.initState();
    authenticationState.addListener(listenForAuthStateChanges);
    authenticationState.checkForExistingToken();
    print("app: init state");
    // TODO handle tapping notifications better
    // widget.selectNotificationSubject?.stream.listen((String payload) async {
    //   print("heard $payload from the stream");
    //   await widget._navigator.currentState?.pushNamed(ShowAlert.routeName);
    // });
  }

  @override
  void dispose() {
    print("disposing");
    isLoading = true;
    widget.selectNotificationSubject?.close();
    authenticationState.removeListener(listenForAuthStateChanges);
    super.dispose();
  }

  void reinitialize([String? newToken]) {
    authenticationState.token = newToken;
    final client = authenticationState.getClient().value;
    client.resetStore(refetchQueries: false);
  }

  @override
  Widget build(BuildContext context) {
    String? initialRoute = widget.initialRoute;

    final client = authenticationState.getClient();

    print("Rendering authenticationState.loading ${authenticationState.loading} and isLoading $isLoading");
    print("Initialroute = $initialRoute");
    if (initialRoute != ShowAlert.routeName && (authenticationState.loading || isLoading)) {
      return const Directionality(textDirection: TextDirection.ltr, child: Text("Checking for token..."));
    }
    if (initialRoute != ShowAlert.routeName && authenticationState.token != null) {
      initialRoute = Home.routeName;
    }
    return GraphQLProvider(
      client: client,
      child: VRouter(
        title: 'HandleIt',
        initialUrl: initialRoute,
        navigatorKey: widget._navigator,
        routes: [
          VWidget(path: Home.routeName, widget: Home(reinitialize: reinitialize)),
          VWidget(path: ShowAlert.routeName, widget: ShowAlert(eventId: widget.eventId)),
          // TODO refactor reinitialize to a provider
          VWidget(path: Register.routeName, widget: Register(reinitialize: reinitialize)),
          VWidget(path: Login.routeName, widget: Login(reinitialize: reinitialize)),
          VWidget(path: AddVehicleWizard.routeName, widget: const AddVehicleWizard()),
          VWidget(path: AddSensorWizard.routeName, widget: const AddSensorWizard()),
        ],
        theme: buildTheme(),
      ),
    );
  }
}
