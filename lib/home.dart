import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed_home.dart';
import 'package:handle_it/settings.dart';

import 'client_provider.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  static String routeName = "/home";

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // pushNotificationService.initialize();

    return Query(
      options: QueryOptions(
        document: addFragments(gql(r"""
        query mainQuery {
          viewer {
            user {
              id
              ...settingsFragment_user
            }
          }
        }
      """), [Settings.settingsFragment]),
      ),
      builder: (QueryResult result, {Refetch refetch, FetchMore fetchMore}) {
        if (result.hasException) return Text(result.exception.toString());
        if (result.isLoading) return Text("Loading...");
        print(result.data['viewer']);
        if (!result.data.containsKey('viewer') || result.data['viewer']['user'] == null) {
          return null;
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text("HandleIt"),
          ),
          body: [FeedHome(), Settings(result.data['viewer']['user'])][_selectedIndex],
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
