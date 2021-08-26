import 'package:flutter/material.dart';
import 'dart:math';

// TODO: Allow custom positioning of the child widget (is only center at the moment)

/// Create a cool 3D rain effect!
class ParallaxRain extends StatefulWidget {
  ParallaxRain(
      {this.key,
      this.numberOfDrops = 200,
      this.dropFallSpeed = 1,
      this.numberOfLayers = 3,
      this.dropHeight = 20,
      this.dropWidth = 1,
      this.dropColors = const [Colors.greenAccent],
      this.trailStartFraction = 0.3,
      this.distanceBetweenLayers = 1,
      this.child,
      this.rainIsInBackground = true,
      this.trail = false})
      : assert(numberOfLayers >= 1, "The minimum number of layers is 1"),
        assert(dropColors.isNotEmpty, "The drop colors list cannot be empty"),
        assert(distanceBetweenLayers > 0,
            "The distance between layers cannot be 0, try setting the number of layers to 1 instead"),
        super(key: key);

  final Key? key;

  /// Number of drops on screen at any moment
  final int numberOfDrops;

  /// Speed at which a drop falls in the vertical direction per frame
  final double dropFallSpeed;

  /// Number of layers for the parallax effect
  final int numberOfLayers;

  /// Height of each drop
  final double dropHeight;

  /// Width of each drop
  final double dropWidth;

  /// Color of each drop
  final List<Color> dropColors;

  /// Fraction of the drop at which the trail effect begins, value ranges from 0.0 to 1.0
  final double trailStartFraction;

  /// Whether the drops have a trail or not
  final bool trail;

  /// Distance between each layer
  final double distanceBetweenLayers;

  /// Whether the rain should be painted behind or in front of the child widget
  final bool rainIsInBackground;

  /// The child widget to display in the center of the rain
  final Widget? child;

  @override
  State<StatefulWidget> createState() {
    return ParallaxRainState();
  }
}

class ParallaxRainState extends State<ParallaxRain> {
  final ValueNotifier notifier = ValueNotifier(false);
  late final parallaxRainPainter;

  runAnimation() async {
    while (true) {
      notifier.value = !notifier.value;
      await Future.delayed(Duration());
    }
  }

  @override
  void initState() {
    super.initState();
    runAnimation();
    parallaxRainPainter = ParallaxRainPainter(
      numberOfDrops: widget.numberOfDrops,
      dropFallSpeed: widget.dropFallSpeed,
      numberOfLayers: widget.numberOfLayers,
      trail: widget.trail,
      dropHeight: widget.dropHeight,
      dropWidth: widget.dropWidth,
      dropColors: widget.dropColors,
      trailStartFraction: widget.trailStartFraction,
      distanceBetweenLayers: widget.distanceBetweenLayers,
      notifier: notifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: (widget.rainIsInBackground) ? parallaxRainPainter : null,
        child: Container(
          child: widget.child,
        ),
        foregroundPainter:
            (widget.rainIsInBackground) ? null : parallaxRainPainter,
      ),
    );
  }
}

class ParallaxRainPainter extends CustomPainter {
  final int numberOfDrops;
  // final Size parentSize;
  List<Drop> dropList = <Drop>[];
  late Paint paintObject;
  late Size dropSize;
  final double dropFallSpeed;
  final double dropHeight;
  final double dropWidth;
  final int numberOfLayers;
  final bool trail;
  final List<Color> dropColors;
  final double trailStartFraction;
  final double distanceBetweenLayers;
  late final ValueNotifier notifier;
  Random random = new Random();

  ParallaxRainPainter({
    // required this.parentSize,
    required this.numberOfDrops,
    required this.dropFallSpeed,
    required this.numberOfLayers,
    required this.trail,
    required this.dropHeight,
    required this.dropWidth,
    required this.dropColors,
    required this.trailStartFraction,
    required this.distanceBetweenLayers,
    required this.notifier,
  }) : super(repaint: notifier);

  void initialize(Canvas canvas, Size size) {
    paintObject = Paint()
      ..color = dropColors[0]
      ..style = PaintingStyle.fill;
    double effectiveLayer;
    for (int i = 0; i < this.numberOfDrops; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      // Keeping [widget.numberOfLayers] layers for the parallax effect, the base values are for the layer furthest behind
      int layerNumber =
          random.nextInt(numberOfLayers); // 0 is the layer furthest behind
      effectiveLayer = layerNumber * distanceBetweenLayers;
      dropSize = new Size(dropWidth, dropHeight);
      dropList.add(
        new Drop(
            drop: Offset(x, y) &
                Size(
                  dropSize.width + (dropSize.width * effectiveLayer),
                  dropSize.height + (dropSize.height * effectiveLayer),
                ),
            dropSpeed:
                this.dropFallSpeed + (this.dropFallSpeed * effectiveLayer),
            dropLayer: layerNumber,
            dropColor: dropColors[random.nextInt(dropColors.length)]),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dropList.isEmpty) {
      initialize(canvas, size);
    }
    double effectiveLayer;
    for (int i = 0; i < this.numberOfDrops; i++) {
      if (dropList[i].drop.top + dropList[i].dropSpeed < size.height) {
        dropList[i].drop = Offset(dropList[i].drop.left,
                dropList[i].drop.top + dropList[i].dropSpeed) &
            dropList[i].drop.size;
      } else {
        int layer = random.nextInt(numberOfLayers);
        effectiveLayer = layer * distanceBetweenLayers;
        dropList[i].drop = Offset(random.nextDouble() * size.width,
                -(dropSize.height + (dropSize.height * effectiveLayer))) &
            Size(dropSize.width + (dropSize.width * effectiveLayer),
                dropSize.height + (dropSize.height * effectiveLayer));
        dropList[i].dropSpeed =
            this.dropFallSpeed + (this.dropFallSpeed * effectiveLayer);
        dropList[i].dropLayer = layer;
        dropList[i].dropColor = dropColors[random.nextInt(dropColors.length)];
      }

      paintObject.color = dropList[i]
          .dropColor
          .withOpacity(((dropList[i].dropLayer + 1) / numberOfLayers));

      // draw drop
      canvas.drawRect(
        dropList[i].drop,
        (trail)
            ? (Paint()
              ..shader = LinearGradient(
                stops: [trailStartFraction, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [paintObject.color, Colors.transparent],
              ).createShader(
                dropList[i].drop,
              ))
            : paintObject,
      );
    }
  }

  @override
  bool shouldRepaint(ParallaxRainPainter oldDelegate) => true;
}

/// Model class for drops in ParallaxRain
class Drop {
  /// Represents a drop by a Rect object, i.e. a combination of Offset and Size
  Rect drop;

  /// The speed at which this drop is travelling
  double dropSpeed;

  /// The layer in which this drop is right now
  int dropLayer;

  /// The color that this drop has right now
  Color dropColor;

  Drop({
    required this.drop,
    required this.dropSpeed,
    required this.dropLayer,
    required this.dropColor,
  });
}
