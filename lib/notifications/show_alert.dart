import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:handle_it/home.dart';
import 'package:just_audio/just_audio.dart';

class ShowAlert extends StatefulWidget {
  static const String routeName = '/showAlert';

  @override
  State<StatefulWidget> createState() => _ShowAlert();
}

class _ShowAlert extends State<ShowAlert> {
  AudioPlayer _audioPlayer;

  void startPlayer() async {
    if (_audioPlayer != null) return;
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer?.setAudioSource(AudioSource.uri(Uri.parse("asset:///assets/audio/mgs_alert.mp3")));
      _audioPlayer?.play();
    } catch (error) {
      print("An error occurred $error");
    }
  }

  @override
  void initState() {
    super.initState();
    startPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void handleDismiss() {
      _audioPlayer?.stop();
      Navigator.of(context).pushReplacementNamed(Home.routeName);
    }

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
            onPressed: handleDismiss,
            child: Text(
              "Dismiss Alert and View",
              textScaleFactor: 1.5,
            ))
      ],
    );
  }
}
