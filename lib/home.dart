import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/feed_home.dart';
import 'package:handle_it/settings/settings.dart';

import 'utils.dart';

class Home extends StatefulWidget {
  final Function reinitialize;
  Home({Key key, this.reinitialize}) : super(key: key);

  static String routeName = "/home";

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

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
              ...settingsFragment_user
            }
          }
        }
      """), [Settings.settingsFragment]),
      ),
      builder: (QueryResult result, {Refetch refetch, FetchMore fetchMore}) {
        if (result.hasException) {
          print("Exception ${result.exception.toString()}");
          return Text(result.exception.toString());
        }
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
          body: [FeedHome(), Settings(result.data['viewer']['user'], this.widget.reinitialize)][_selectedIndex],
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
