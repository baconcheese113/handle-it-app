import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:handle_it/feed/updaters/~graphql/__generated__/updaters.fragments.graphql.dart';
import 'package:mcumgr/mcumgr.dart';
import 'package:version/version.dart';

import '../../common/ble_provider.dart';

class HubUpdater extends StatefulWidget {
  final Fragment$hubUpdater_hub hubFrag;
  final BluetoothDevice foundHub;
  const HubUpdater({Key? key, required this.hubFrag, required this.foundHub}) : super(key: key);

  @override
  State<HubUpdater> createState() => _HubUpdaterState();
}

class _HubUpdaterState extends State<HubUpdater> {
  bool _installed = false;
  double _progressPercent = -1;
  Version? _hubVersion;
  File? _update;
  int? _startTime;
  Client? _client;

  void checkVersion() async {
    await Future.delayed(const Duration(seconds: 2));
    print(">>> checking version");
    List<BluetoothService> services = await widget.foundHub.discoverServices();

    BluetoothService hubService = services.firstWhere((s) => s.uuid == Guid(HUB_SERVICE_UUID));
    BluetoothCharacteristic firmwareChar =
        hubService.characteristics.firstWhere((c) => c.uuid == Guid(FIRMWARE_CHARACTERISTIC_UUID));

    final bytes = await firmwareChar.read();
    final hubVersionStr = utf8.decode(bytes).replaceAll(RegExp(r'\x00'), "");
    print(">>> hub software version string: $hubVersionStr");
    final hubVersion = Version.parse(hubVersionStr);
    print(">>> parsed to $hubVersion");
    setState(() => _hubVersion = hubVersion);
  }

  void _initializeClient() async {
    print(">>> initializing client");
    final services = await widget.foundHub.discoverServices();
    final smpService = services.firstWhere((s) => s.uuid == Guid(SMP_SERVICE_UUID));
    final smpChar = smpService.characteristics.firstWhere((c) => c.uuid == Guid(SMP_UPDATE_CHARACTERISTIC_UUID));
    // Some amount of delay needed for setNotifyValue() to work
    await Future.delayed(const Duration(milliseconds: 500));
    final notifyVal = await smpChar.setNotifyValue(true);
    print(">>> notifyVal is $notifyVal");

    final mtu = Platform.isIOS ? await widget.foundHub.mtu.last : await widget.foundHub.requestMtu(252);
    print(">>> new mtu is $mtu");

    final newClient = Client(
      input: smpChar.onValueChangedStream.handleError((err) {
        //  ignore errors
      }),
      output: (msg) => smpChar.write(msg, withoutResponse: true),
    );
    print(">>> newClient setup");
    final newImageState = await newClient.readImageState(const Duration(seconds: 2));
    print("new image state is ${newImageState.toString()}");
    // before image sent
    //ImageState{images: [Image{slot: 0, version: 0.0.0, hash: [228, 197, 224, etc...], bootable: true, pending: false, confirmed: true, active: true, permanent: false}, Image{slot: 1, version: 0.0.0, hash: [212, 177, 159, etc...], bootable: true, pending: false, confirmed: false, active: false, permanent: false}], splitStatus: 0}
    // after image sent and set as pending and confirmed
    //ImageState{images: [Image{slot: 0, version: 0.0.0, hash: [228, 197, 224, etc...], bootable: true, pending: false, confirmed: true, active: true, permanent: false}, Image{slot: 1, version: 0.0.0, hash: [212, 177, 159, etc...], bootable: true, pending: true, confirmed: false, active: false, permanent: true}], splitStatus: 0}

    setState(() {
      _client = newClient;
    });
  }

  @override
  void initState() {
    checkVersion();
    _initializeClient();
    super.initState();
  }

  void downloadUpdate() async {
    // the downloads are so quick (<1MB) that it's not worth setting an actual value
    setState(() => _progressPercent = .5);
    final file = await DefaultCacheManager().getSingleFile("${dotenv.env['FIRMWARE_SERVER_URL']}/hub-0-1-1.bin");
    setState(() {
      _update = file;
      _progressPercent = -1;
    });
  }

  void installUpdate() async {
    final stateStreamSub = widget.foundHub.state.listen((state) {
      print(">>> New connection state is: $state");
    });

    setState(() {
      _progressPercent = 0;
      _startTime = DateTime.now().microsecondsSinceEpoch;
    });

    final content = await _update!.readAsBytes();
    final image = McuImage.decode(content);

    try {
      await _client!.uploadImage(
        0,
        content,
        image.hash,
        const Duration(seconds: 30),
        onProgress: (count) {
          print(">>> progress $count of ${content.length}");
          setState(() => _progressPercent = count.toDouble() / content.length);
        },
      );
    } catch (err) {
      print(">>> Error: $err");
    } finally {
      print(">>> DFU complete");
    }

    const timeout = Duration(seconds: 10);
    final newPendingState = await _client!.setPendingImage(image.hash, true, timeout);
    print(">>> newPendingState set ${newPendingState.toString()}, now resetting");
    // ImageState{images: [Image{slot: 0, version: 0.0.0, hash: [143, 252, 237, 139, 193, 30, 150, 213, 126, 228, 234, 22, 1, 229, 217, 93, 91, 211, 111, 145, 40, 94, 27, 207, 2, 88, 84, 30, 41, 228, 197, 224], bootable: true, pending: false, confirmed: true, active: true, permanent: false}, Image{slot: 1, version: 0.0.0, hash: [139, 73, 99, 110, 15, 155, 119, 219, 123, 133, 46, 87, 50, 182, 125, 116, 111, 57, 41, 182, 52, 111, 163, 57, 246, 157, 215, 61, 13, 212, 177, 159], bootable: true, pending: true, confirmed: false, active: false, permanent: true}], splitStatus: 0}
    await _client!.reset(timeout);
    print(">>> reset sent");

    stateStreamSub.cancel();
    await DefaultCacheManager().emptyCache();
    setState(() {
      _installed = true;
      _update = null;
      _startTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hubVersion == null) return const SizedBox();
    final hubVersionCurrent = _hubVersion!.compareTo(Version.parse(widget.hubFrag.latestVersion)) >= 0;
    if (_installed || hubVersionCurrent) return Text("Current version: v$_hubVersion");
    if (_startTime != null && _progressPercent.isFinite && _progressPercent > 0.0) {
      final microsecondsElapsed = DateTime.now().microsecondsSinceEpoch - _startTime!;
      final totalEstMicroseconds = microsecondsElapsed / _progressPercent;
      final timeRemaining = Duration(microseconds: (totalEstMicroseconds - microsecondsElapsed).round());
      return Column(
        children: [
          LinearProgressIndicator(value: _progressPercent),
          Text("${(_progressPercent * 100).toStringAsFixed(2)}%"),
          Text("${timeRemaining.inMinutes}m ${timeRemaining.inSeconds % 60}s remaining"),
        ],
      );
    }
    if (_progressPercent > -1) return LinearProgressIndicator(value: _progressPercent);
    if (_update != null) return TextButton(onPressed: installUpdate, child: const Text("Install"));
    return TextButton(onPressed: downloadUpdate, child: const Text("Download update"));
  }
}
