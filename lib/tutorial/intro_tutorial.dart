import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final introTutPrefKey = "introTutComplete";
final APP_GREEN = Color.fromRGBO(125, 229, 120, 1);
final slideInfo = [
  {
    "title": "Add Sensors\nand a Hub",
    "body": "First add a Hub for your vehicle. "
        "Then to track each handle of your car, pair their sensors with your hub. "
        "Now your can receive notifications when someone is trying to get in to your car"
  },
  {
    "title": "Alert your neighbors",
    "body": "Team up with your neighbors so everyone is alerted when a thief is in the area. "
        "Create or join networks and configure your notification settings"
  }
];

class IntroTutorial extends StatefulWidget {
  final Function tutorialComplete;
  const IntroTutorial({this.tutorialComplete});

  @override
  State<IntroTutorial> createState() => _IntroTutorialState();
}

class _IntroTutorialState extends State<IntroTutorial> {
  int _slideNum = 0;

  void finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(introTutPrefKey, true);
    this.widget.tutorialComplete();
  }

  void advanceSlide() {
    if (_slideNum > 0)
      finishTutorial();
    else
      setState(() => _slideNum = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.lerp(Alignment.topCenter, Alignment.center, .5),
        end: Alignment.bottomCenter,
        colors: [Colors.white, APP_GREEN],
      )),
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(-100, -150),
            child: Transform.scale(
              scale: 2.5,
              child: Opacity(
                opacity: .2,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.transparent])),
                    alignment: Alignment.bottomLeft,
                    child: Image.asset("assets/images/logo.png", fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        child: Image.asset("assets/images/tutorial_${_slideNum + 1}.png"),
                        height: 256,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(slideInfo[_slideNum]["title"],
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              slideInfo[_slideNum]["body"],
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_slideNum < 1) ElevatedButton(onPressed: finishTutorial, child: Text("Skip")),
                    ElevatedButton(onPressed: advanceSlide, child: Text(_slideNum > 0 ? "Finish" : "Next")),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
