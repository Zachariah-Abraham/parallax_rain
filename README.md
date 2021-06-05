[![Pub Version](https://img.shields.io/pub/v/glass.svg?style=flat-square)](https://pub.dev/packages/parallax_rain)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

# Parallax Rain
Create a cool 3D rain effect, with plenty of customization!

![Sample screenshot](https://raw.githubusercontent.com/Zachariah-Abraham/parallax_rain/main/example/screenshots/1.PNG)

![Sample video](https://user-images.githubusercontent.com/24973509/120873946-e964f600-c5c1-11eb-8cc1-eabb493ddee2.mp4)



## Installation

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
    parallax_rain:
```


### 2. Install it

You can install packages from the command line:

```bash
$ pub get
..
```

Alternatively, your editor might support pub. Check the docs for your editor to learn more.

### 3. Import it

Now in your Flutter code, you can use:

```Dart
import 'package:parallax_rain/parallax_rain.dart';
```

## Usage

If you want to give `YourWidget` a 3D rain background, simple wrap it with the `ParallaxRain` widget, with `YourWidget` as the child parameter. You can also have the rain effect in the foreground, use multiple drop colors, adjust the speed, add trails to your drops and lots more! 

For example: 

```Dart
ParallaxRain(
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
```

A full example can be found in the example directory

## About me

Visit my LinkedIn at https://www.linkedin.com/in/zaca 

I'm also the author of the Flutter glass package that allows you to convert any flutter widget into a glass/frosted glass version of itself, check it out at https://pub.dev/packages/glass
