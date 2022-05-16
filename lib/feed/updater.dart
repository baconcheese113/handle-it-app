import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:handle_it/feed/add_vehicle_wizard_content.dart';
import 'package:http/http.dart' as http;

const String TRANSFER_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fe";
const String FIRMWARE_CHARACTERISTIC_UUID = "00002A26-0000-1000-8000-00805f9b34fb";

class Updater extends StatefulWidget {
  final Map<String, dynamic> hub;
  final BluetoothDevice foundHub;
  const Updater({Key? key, required this.hub, required this.foundHub}) : super(key: key);

  static final updaterFragment = gql(r'''
    fragment updater_hub on Hub {
      id
      latestVersion
    }
    ''');

  @override
  State<Updater> createState() => _UpdaterState();
}

class _UpdaterState extends State<Updater> {
  bool _installed = false;
  double _progressPercent = -1;
  int _hubVersion = -1;
  int? _startTime;
  final List<int> _firmwareBin = [];

  void checkVersion() async {
    print(">>> checking version");
    List<BluetoothService> services = await widget.foundHub.discoverServices();

    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic firmwareChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(FIRMWARE_CHARACTERISTIC_UUID));

    final bytes = await firmwareChar.read();
    final arr = Int8List.fromList(bytes);
    final num = ByteData.sublistView(arr);
    final hubVersion = num.getInt32(0, Endian.little);
    print(">>> found version: v$hubVersion");
    setState(() => _hubVersion = hubVersion);
  }

  @override
  void initState() {
    checkVersion();
    super.initState();
  }

  void downloadUpdate() async {
    final req =
        await http.Client().send(http.Request('GET', Uri.parse("${dotenv.env['FIRMWARE_SERVER_URL']}/update-v2.bin")));
    int total = req.contentLength ?? 0;
    print("ContentLength is $total");
    req.stream.listen((newBytes) {
      _firmwareBin.addAll(newBytes);
      int received = _firmwareBin.length;
      print('newBytes length is ${newBytes.length} and we\'ve received $received so far');
      setState(() => _progressPercent = received / total);
    }).onDone(() {
      print('stream complete');
      setState(() => _progressPercent = -1);
    });
  }

  void installUpdate() async {
    late BluetoothDeviceState deviceState;
    final stateStreamSub = widget.foundHub.state.listen((state) {
      deviceState = state;
      print(">>> New connection state is: $state");
    });

    setState(() {
      _progressPercent = 0;
      _startTime = DateTime.now().microsecondsSinceEpoch;
    });
    print(">>> discoveringservices");
    List<BluetoothService> services = await widget.foundHub.discoverServices();

    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic commandChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(COMMAND_CHARACTERISTIC_UUID));
    BluetoothCharacteristic transferChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(TRANSFER_CHARACTERISTIC_UUID));
    // clear out any left over artifacts
    await transferChar.write([]);

    String command = "StartHubUpdate:${_firmwareBin.length}";
    List<int> bytes = utf8.encode(command);
    print(">>> writing characteristic with value $command");
    Uint8List hubUpdateCharValue = Uint8List.fromList(bytes);
    await commandChar.write(hubUpdateCharValue);

    int lastChunkEnd = 0;
    int chunkSize = 250;

    while (deviceState == BluetoothDeviceState.connected) {
      List<int> bytes = await transferChar.read();
      print(">>readCharacteristic ${bytes.toString()}");
      if (bytes.length > 2) continue;
      int end = min(lastChunkEnd + chunkSize, _firmwareBin.length);
      List<int> bytesToWrite = _firmwareBin.getRange(lastChunkEnd, end).toList();
      print(">>> writing bytes: $bytesToWrite");
      await transferChar.write(bytesToWrite);
      setState(() => _progressPercent = lastChunkEnd / _firmwareBin.length);
      print(">>> _progressPercent is: $_progressPercent");
      lastChunkEnd = end;
      if (end >= _firmwareBin.length - 1) break;
    }

    if (lastChunkEnd < _firmwareBin.length) {
      print(">>> transfer timed out");
      setState(() {
        _progressPercent = -1;
        _startTime = null;
      });
      stateStreamSub.cancel();
      return;
    }

    String hubUpdateEndResponse = "";
    while (hubUpdateEndResponse.length < 13 || hubUpdateEndResponse.substring(0, 12) != "HubUpdateEnd") {
      List<int> bytes = await commandChar.read();
      print(">>readCharacteristic ${bytes.toString()}");
      hubUpdateEndResponse = String.fromCharCodes(bytes);
      print(">>hubUpdateEndResponse = $hubUpdateEndResponse");
    }
    int hubUpdateEndResult = int.parse(hubUpdateEndResponse.substring(13));
    stateStreamSub.cancel();

    setState(() {
      _installed = true;
      _hubVersion = hubUpdateEndResult;
      _startTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hubVersion < 0) return const SizedBox();
    if (_installed || _hubVersion >= widget.hub['latestVersion']) return Text("Current version: v$_hubVersion");
    if (_startTime != null && _progressPercent.isFinite && _progressPercent > 0.0) {
      final microsecondsElapsed = DateTime.now().microsecondsSinceEpoch - _startTime!;
      final totalEstMicroseconds = microsecondsElapsed / _progressPercent;
      final timeRemaining = Duration(microseconds: (totalEstMicroseconds - microsecondsElapsed).round());
      print(">>> $microsecondsElapsed microseconds elapsed, $totalEstMicroseconds total est microseconds");
      return Column(
        children: [
          LinearProgressIndicator(value: _progressPercent),
          Text("${(_progressPercent * 100).toStringAsFixed(2)}%"),
          Text("${timeRemaining.inMinutes}m ${timeRemaining.inSeconds % 60}s remaining"),
        ],
      );
    }
    if (_progressPercent > -1) return LinearProgressIndicator(value: _progressPercent);
    if (_firmwareBin.isNotEmpty) return TextButton(onPressed: installUpdate, child: const Text("Install"));
    return TextButton(onPressed: downloadUpdate, child: const Text("Download update"));
  }
}
