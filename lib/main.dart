import 'package:flutter/material.dart';
import 'package:handle_it/feed_home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandleIt',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("HandleIt"),
        ),
        body: FeedHome(),
      ),
    );
  }
}
