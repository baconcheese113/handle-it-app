import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:handle_it/add_vehicle_wizard.dart';
import 'package:handle_it/feed_card.dart';
import 'package:just_audio/just_audio.dart';

class FeedHome extends StatefulWidget {
  @override
  _FeedHomeState createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> {
  bool _showAddVehicleWizard = false;
  List<Peripheral> _hubs = [];
  String _hubCustomName = '';
  BleManager _bleManager;
  AudioPlayer _audioPlayer;
  static const platform = const MethodChannel('flutter.native/helper');

  @override
  void initState() {
    super.initState();
    print("initState");
    _audioPlayer = AudioPlayer();
    _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse("asset:///assets/audio/alarm.mp3"))).catchError((error) {
      print("An error occured $error");
    });
    _bleManager = BleManager();
    _bleManager.createClient();
  }

  @override
  void dispose() {
    _bleManager.destroyClient();
    _audioPlayer.dispose();
    super.dispose();
  }

  void handleExit([String hubCustomName, Peripheral hub]) {
    setState(() {
      _showAddVehicleWizard = false;
      if (_hubCustomName != null) _hubCustomName = hubCustomName;
      if (hub != null) _hubs.add(hub);
    });
  }

  void handleAddVehicle() {
    setState(() => _showAddVehicleWizard = true);
  }

  void _handleDisconnect() {
    setState(() => _hubs.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddVehicleWizard == true) {
      return AddVehicleWizard(onExit: handleExit, bleManager: _bleManager);
    }

    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
            onPressed: this.handleAddVehicle,
            child:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add), Text("Add New Vehicle")])),
        TextButton(
            onPressed: () async {
              // await _audioPlayer.play();
              String response = "";
              try {
                final int result = await platform.invokeMethod('getBatteryLevel');
                response = "Response: $result";
              } on PlatformException catch (e) {
                response = "Failed to Invoke: '${e.message}'.";
              }
              print(response);
            },
            child: Text("Click me")),
        ..._hubs
            .map((hub) => FeedCard(
                  hub: hub,
                  name: _hubCustomName,
                  bleManager: _bleManager,
                  onDisconnect: _handleDisconnect,
                ))
            .toList(),
      ],
    );
  }
}
