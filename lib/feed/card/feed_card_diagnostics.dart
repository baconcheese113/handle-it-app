import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/common/ble_provider.dart';
import 'package:provider/provider.dart';

class FeedCardDiagnostics extends StatefulWidget {
  BluetoothDevice foundHub;

  FeedCardDiagnostics({super.key, required this.foundHub});

  @override
  State<FeedCardDiagnostics> createState() => _FeedCardDiagnosticsState();
}

class _FeedCardDiagnosticsState extends State<FeedCardDiagnostics> {
  late BleProvider _bleProvider;
  BluetoothCharacteristic? _commandChar;
  String _resultMsg = "";

  Future<void> _startDiagnostic() async {
    final commandChar = await _bleProvider.getChar(
      widget.foundHub,
      HUB_SERVICE_UUID,
      COMMAND_CHARACTERISTIC_UUID,
    );
    if (commandChar == null) return;
    setState(() => _commandChar = commandChar);

    String command = "StartDiagnostic:1";
    print(">>> writing characteristic with value $command");
    await _commandChar!.write(utf8.encode(command));
    print(">>> commandChar written!");
    // Some amount of delay needed for setNotifyValue() to work
    await Future.delayed(const Duration(milliseconds: 500));
    await _commandChar!.setNotifyValue(true);
    final stream = _commandChar!.onValueChangedStream.listen((value) {
      print(">>> commandChar new value: $value");
    });

    String rawDiagResult = "";
    String prevMsg = "";
    int startTime = DateTime.now().millisecondsSinceEpoch;
    while (!rawDiagResult.endsWith("END") &&
        DateTime.now().millisecondsSinceEpoch < startTime + 120000) {
      List<int> bytes = await _commandChar!.read();
      print(">>readCharacteristic ${bytes.toString()}");
      rawDiagResult = String.fromCharCodes(bytes);
      print(">>rawDiagResult = $rawDiagResult");
      if (rawDiagResult.length > 16 && rawDiagResult.startsWith("DiagnosticResult:")) {
        final diagResult = rawDiagResult.substring(17);
        if (diagResult.endsWith("END")) break;
        if (prevMsg != diagResult) {
          setState(() => _resultMsg += diagResult);
          prevMsg = diagResult;
        }
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    print(">>> Ending stream");
    await stream.cancel();
    setState(() => _commandChar = null);
  }

  @override
  Widget build(BuildContext context) {
    _bleProvider = Provider.of<BleProvider>(context, listen: true);

    if (_commandChar != null || _resultMsg.isNotEmpty) {
      return Column(children: [
        Center(child: Text(_resultMsg)),
        if (_commandChar != null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(height: 10, child: CircularProgressIndicator()),
          ),
      ]);
    }
    return TextButton(
      onPressed: _commandChar == null ? _startDiagnostic : null,
      child: const Text("Start Network Diagnostics"),
    );
  }
}
