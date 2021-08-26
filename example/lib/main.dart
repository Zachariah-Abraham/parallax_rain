import 'package:flutter/material.dart';
import 'package:parallax_rain/parallax_rain.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parallax Rain',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Key parallaxOne = GlobalKey();
  final Key parallaxTwo = GlobalKey();
  final Key parallaxThree = GlobalKey();
  final Key parallaxFour = GlobalKey();
  int counter = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ParallaxRain(
                    key: parallaxOne,
                    dropColors: [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                      Colors.yellow,
                      Colors.brown,
                      Colors.blueGrey
                    ],
                    child: Center(
                      child: TextButton(
                        child: Text(
                          "Multicolor with setState (press here): $counter",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            counter++;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ParallaxRain(
                    key: parallaxTwo,
                    dropColors: [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                      Colors.yellow,
                      Colors.brown,
                      Colors.blueGrey
                    ],
                    trail: true,
                    child: Center(
                      child: Text(
                        "Multicolor Trail",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ParallaxRain(
                    key: parallaxThree,
                    dropColors: [Colors.blueGrey],
                    trail: true,
                    child: Center(
                      child: Text(
                        "BlueGrey Trail",
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ParallaxRain(
                    key: parallaxFour,
                    dropColors: [Colors.blueGrey],
                    trail: true,
                    dropFallSpeed: 5,
                    child: Center(
                      child: Text(
                        "BlueGrey Trail Fast",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
