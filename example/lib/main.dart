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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ParallaxRain(
                    dropColors: [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                      Colors.yellow,
                      Colors.brown,
                      Colors.blueGrey
                    ],
                    child: Text(
                      "Multicolor",
                    ),
                  ),
                ),
                Expanded(
                  child: ParallaxRain(
                    dropColors: [
                      Colors.red,
                      Colors.green,
                      Colors.blue,
                      Colors.yellow,
                      Colors.brown,
                      Colors.blueGrey
                    ],
                    trail: true,
                    child: Text(
                      "Multicolor Trail",
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ParallaxRain(
                    dropColors: [Colors.blueGrey],
                    trail: true,
                    child: Text(
                      "BlueGrey Trail",
                    ),
                  ),
                ),
                Expanded(
                  child: ParallaxRain(
                    dropColors: [Colors.blueGrey],
                    trail: true,
                    dropFallSpeed: 5,
                    child: Text(
                      "BlueGrey Trail Fast",
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
