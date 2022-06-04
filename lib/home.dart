import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard.dart';
import 'package:handle_it/feed/feed_home.dart';
import 'package:handle_it/settings/settings.dart';
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils.dart';

class Home extends StatefulWidget {
  final Function reinitialize;
  const Home({Key? key, required this.reinitialize}) : super(key: key);

  static String routeName = "/home";

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _introTutComplete = false;

  void loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(introTutPrefKey)) {
      print("prefs has already set $introTutPrefKey");
      _introTutComplete = prefs.getBool(introTutPrefKey) ?? false;
    } else {
      print("prefs doesn't contain $introTutPrefKey");
    }
  }

  @override
  void initState() {
    loadPrefs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("Rendering home");

    return Query(
      options: QueryOptions(
        document: addFragments(gql(r"""
        query mainQuery {
          viewer {
            user {
              id
              ...settings_user
            }
          }
        }
      """), [Settings.settingsFragment]),
      ),
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          print("Exception ${result.exception.toString()}");
          return Text(result.exception.toString());
        }
        if (result.isLoading) return const Text("Loading...");
        print(result.data!['viewer']);
        if (!result.data!.containsKey('viewer') || result.data!['viewer']['user'] == null) {
          return const SizedBox();
        }

        if (!_introTutComplete) {
          return IntroTutorial(tutorialComplete: () {
            setState(() => _introTutComplete = true);
          });
        }
        void _handleAddVehicle() {
          Navigator.pushNamed(context, AddVehicleWizard.routeName);
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("HandleIt", style: TextStyle(fontFamily: 'Julius Sans One')),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: [const FeedHome(), Settings(result.data!['viewer']['user'], widget.reinitialize)][_selectedIndex],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _handleAddVehicle,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Add Hub", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.amberAccent,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Feed"),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile')
            ],
            currentIndex: _selectedIndex,
            onTap: (newIndex) => setState(() => _selectedIndex = newIndex),
          ),
        );
      },
    );
  }
}
