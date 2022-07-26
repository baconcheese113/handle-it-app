import 'package:flutter/material.dart';
import 'package:handle_it/common/loading.dart';
import 'package:handle_it/feed/feed_home.dart';
import 'package:handle_it/network/network_home.dart';
import 'package:handle_it/settings/settings.dart';
import 'package:handle_it/tutorial/intro_tutorial.dart';
import 'package:handle_it/utils.dart';
import 'package:handle_it/~graphql/__generated__/home.query.graphql.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feed/add_wizards/add_vehicle_wizard.dart';

class Home extends StatefulWidget {
  final Function reinitialize;
  const Home({Key? key, required this.reinitialize}) : super(key: key);

  static String routeName = "/home";

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool? _introTutComplete;

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    var tutComplete = prefs.getBool(introTutPrefKey) ?? false;
    print("Intro tutorial has ${tutComplete ? "" : "not "}been completed");
    setState(() => _introTutComplete = tutComplete);
  }

  @override
  void initState() {
    _loadPrefs();
    super.initState();
  }

  void _handleAddVehicle(BuildContext c) {
    Navigator.pushNamed(c, AddVehicleWizard.routeName);
  }

  @override
  Widget build(BuildContext context) {
    if (_introTutComplete == null) return const Loading();
    if (!_introTutComplete!) {
      return IntroTutorial(tutorialComplete: () {
        setState(() => _introTutComplete = true);
      });
    }

    return Query$Home$Widget(
      builder: (result, {fetchMore, refetch}) {
        final noDataWidget = validateResult(result);
        if (noDataWidget != null) return noDataWidget;

        final viewer = result.parsedData!.viewer;
        final addVehicleFab = FloatingActionButton.extended(
          key: const ValueKey('fab'),
          onPressed: () => _handleAddVehicle(context),
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text("Add Hub", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
        );

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("HandleIt", style: TextStyle(fontFamily: 'Julius Sans One')),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: [
              const FeedHome(),
              const NetworkHome(),
              Settings(viewer.user, widget.reinitialize),
            ][_selectedIndex],
          ),
          floatingActionButton: _selectedIndex == 0 ? addVehicleFab : null,
          bottomNavigationBar: BottomNavigationBar(
            key: const ValueKey('bottomNavBar'),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(key: ValueKey('navIcon.feed'), Icons.home),
                label: "Feed",
              ),
              BottomNavigationBarItem(
                icon: Icon(key: ValueKey('navIcon.network'), Icons.group),
                label: 'HandleUs',
              ),
              BottomNavigationBarItem(
                icon: Icon(key: ValueKey('navIcon.profile'), Icons.settings),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (newIndex) => setState(() => _selectedIndex = newIndex),
          ),
        );
      },
    );
  }
}
