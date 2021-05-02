import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ShowAlert extends StatelessWidget {
  final Function onDismiss;
  ShowAlert({this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(children: [
          Icon(
            Icons.warning,
            size: 200,
            color: Colors.red,
          ),
          Text("Handle pull detected", textScaleFactor: 1.4),
        ]),
        TextButton(
            onPressed: onDismiss,
            child: Text(
              "Dismiss Alert and View",
              textScaleFactor: 1.5,
            ))
      ],
    );
  }
}
