import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:handle_it/add_vehicle_wizard.dart';
import 'package:handle_it/feed_card.dart';
import 'package:handle_it/show_alert.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedHome extends StatefulWidget {
  @override
  _FeedHomeState createState() => _FeedHomeState();
}

class _FeedHomeState extends State<FeedHome> with WidgetsBindingObserver {
  bool _showAddVehicleWizard = false;
  List<Peripheral> _hubs = [];
  String _hubCustomName = '';
  BleManager _bleManager;
  AudioPlayer _audioPlayer;
  bool _isAlert = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse("asset:///assets/audio/alarm.mp3"))).catchError((error) {
      print("An error occured $error");
    });
    _bleManager = BleManager();
    _bleManager.createClient();
    WidgetsBinding.instance.addObserver(this);
    getIsAlert();
  }

  @override
  void dispose() {
    _bleManager.destroyClient();
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    getIsAlert();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("contains (didChangeAppLifecycleState) with $state and _isAlert $_isAlert");
    getIsAlert();
  }

  void getIsAlert() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    bool isAlert = (prefs.containsKey("isAlert") && prefs.getBool("isAlert")) ?? false;
    // await prefs.setBool("isAlert", false);
    if (isAlert) _audioPlayer.play();
    setState(() => {_isAlert = isAlert});
  }

  void _handleExit([String hubCustomName, Peripheral hub]) {
    setState(() {
      _showAddVehicleWizard = false;
      if (_hubCustomName != null) _hubCustomName = hubCustomName;
      if (hub != null) _hubs.add(hub);
    });
  }

  void _handleAddVehicle() {
    setState(() => _showAddVehicleWizard = true);
  }

  void _handleDisconnect() {
    setState(() => _hubs.removeLast());
  }

  void _handleDismissAlert() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isAlert", false);
    prefs.reload();
    _audioPlayer.stop();
    setState(() => _isAlert = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAlert) {
      return ShowAlert(onDismiss: _handleDismissAlert);
    }

    if (_showAddVehicleWizard == true) {
      return AddVehicleWizard(onExit: _handleExit, bleManager: _bleManager);
    }

    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: _handleAddVehicle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              Text("Add New Vehicle"),
            ],
          ),
        ),
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
