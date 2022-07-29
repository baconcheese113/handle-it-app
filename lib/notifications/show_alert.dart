import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handle_it/home.dart';
import 'package:handle_it/notifications/~graphql/__generated__/show_alert.mutation.graphql.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vrouter/vrouter.dart';

const int interval = 50;
const int numLoops = 10000 ~/ interval;

class ShowAlert extends StatefulWidget {
  static const routeName = '/showAlert';
  final String? eventId;
  const ShowAlert({Key? key, required this.eventId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ShowAlert();
}

class _ShowAlert extends State<ShowAlert> {
  AudioPlayer? _audioPlayer;
  Timer? _timer;
  int _loopNum = numLoops;
  bool _canSendMutation = false;

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

  void startTimer() {
    _timer = Timer.periodic(
      const Duration(milliseconds: interval),
      (timer) {
        if (_loopNum == 0) {
          _timer!.cancel();
        } else {
          setState(() => --_loopNum);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _canSendMutation = widget.eventId?.isNotEmpty ?? false;
    if (_canSendMutation) startTimer();
    startPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void handleDismiss() {
      _audioPlayer?.stop();
      context.vRouter.to(Home.routeName, isReplacement: true);
    }

    return Mutation$PropagateEventToNetworks$Widget(builder: (runMutation, result) {
      if (_canSendMutation && _loopNum == 0) {
        runMutation(
          Variables$Mutation$PropagateEventToNetworks(
            eventId: int.parse(widget.eventId!),
          ),
        );
        _canSendMutation = false;
      }
      Widget getProgressWidget() {
        if (result?.data != null) return const Text("Sent to network");
        if (_loopNum > 0 && _canSendMutation) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Preparing to alert network"),
              LinearProgressIndicator(value: _loopNum / numLoops),
            ],
          );
        }
        if (_loopNum > 0 && !_canSendMutation) return const SizedBox();
        if (result == null || result.isLoading) return const Text("Sending to network members....");
        return const Text("An error occurred");
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          getProgressWidget(),
          Column(children: const [
            Icon(
              Icons.warning,
              size: 200,
              color: Colors.red,
            ),
            Text("Handle pull detected", textScaleFactor: 1.4),
          ]),
          TextButton(
              onPressed: handleDismiss,
              child: const Text(
                "Dismiss Alert and View",
                textScaleFactor: 1.5,
              ))
        ],
      );
    });
  }
}
