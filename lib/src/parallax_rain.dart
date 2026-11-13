import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

/// The default drop color, Material's `Colors.greenAccent`. The package doesn't import the Material
/// library.
const Color _greenAccent = Color(0xFF69F0AE);

// TODO: Allow custom positioning of the child widget (is only center at the moment)

/// Create a cool 3D rain effect!
class ParallaxRain extends StatefulWidget {
  ParallaxRain(
      {Key? key,
      this.numberOfDrops = 200,
      this.dropFallSpeed = 1,
      this.numberOfLayers = 3,
      this.dropHeight = 20,
      this.dropWidth = 1,
      this.dropColors = const [_greenAccent],
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

  /// Number of drops on screen at any moment
  final int numberOfDrops;

  /// Speed at which a drop falls in the vertical direction, in logical pixels per frame at 60 frames
  /// per second. Drops fall at the same speed on displays with other refresh rates.
  final double dropFallSpeed;

  /// Number of layers for the parallax effect
  final int numberOfLayers;

  /// Height of each drop
  final double dropHeight;

  /// Width of each drop
  final double dropWidth;

  /// Colors of the drops. Each drop gets a random color from this list. Defaults to green
  /// (`Colors.greenAccent`, `Color(0xFF69F0AE)`).
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

class ParallaxRainState extends State<ParallaxRain>
    with SingleTickerProviderStateMixin {
  /// Changes every frame to repaint [parallaxRainPainter].
  final ValueNotifier notifier = ValueNotifier(false);
  late ParallaxRainPainter parallaxRainPainter;
  Ticker? _ticker;

  /// Starts the animation. It starts automatically, so there's no need to call this.
  @Deprecated(
      'The animation starts automatically. This will be removed in a future release.')
  void runAnimation() {
    _ticker ??= createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    parallaxRainPainter._elapsed = elapsed;
    notifier.value = !notifier.value;
  }

  @override
  void initState() {
    super.initState();
    parallaxRainPainter = _createPainter();
    // ignore: deprecated_member_use_from_same_package
    runAnimation();
  }

  ParallaxRainPainter _createPainter() {
    return ParallaxRainPainter(
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
  void didUpdateWidget(ParallaxRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ParallaxRain w = widget;
    if (w.numberOfDrops != oldWidget.numberOfDrops ||
        w.dropFallSpeed != oldWidget.dropFallSpeed ||
        w.numberOfLayers != oldWidget.numberOfLayers ||
        w.dropHeight != oldWidget.dropHeight ||
        w.dropWidth != oldWidget.dropWidth ||
        !listEquals(w.dropColors, oldWidget.dropColors) ||
        w.trailStartFraction != oldWidget.trailStartFraction ||
        w.distanceBetweenLayers != oldWidget.distanceBetweenLayers ||
        w.trail != oldWidget.trail) {
      // A new painter with the new settings takes over the drops, so the rain doesn't reset.
      parallaxRainPainter = _createPainter().._takeOver(parallaxRainPainter);
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    notifier.dispose();
    super.dispose();
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

/// The duration of one frame at 60 frames per second, the unit of [ParallaxRain.dropFallSpeed].
const Duration _referenceFrame = Duration(microseconds: 16667);

/// Drops move at most this many reference frames per paint, so they don't jump after a pause.
const double _maxFramesPerPaint = 6;

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
  Random random = Random();

  /// Animation time, set by [ParallaxRainState] every frame. While it is null (when the painter is
  /// used on its own), drops move one reference frame per paint.
  Duration? _elapsed;
  Duration? _lastPaintElapsed;

  /// The canvas size of the last paint, to move the drops along when the size changes.
  Size? _lastSize;

  /// Paints per drop color and layer, created on first use. For trails the shader is in the drop's
  /// local coordinates, so the same paint works for every drop of that color and layer.
  final Map<Color, List<Paint?>> _paints = <Color, List<Paint?>>{};

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

  /// Scatters drops randomly over the canvas until there are [numberOfDrops].
  void initialize(Canvas canvas, Size size) {
    paintObject = Paint()
      ..color = dropColors[0]
      ..style = PaintingStyle.fill;
    dropSize = Size(dropWidth, dropHeight);
    while (dropList.length < numberOfDrops) {
      // Keeping [widget.numberOfLayers] layers for the parallax effect, the base values are for the layer furthest behind
      final drop = Drop(
          drop: Rect.zero,
          dropSpeed: 0,
          dropLayer: 0,
          dropColor: dropColors[0]);
      _respawn(drop, size, top: random.nextDouble() * size.height);
      dropList.add(drop);
    }
  }

  /// Takes over the drops of [old], the painter this one replaces, and applies this painter's
  /// settings to them while keeping their positions.
  void _takeOver(ParallaxRainPainter old) {
    _elapsed = old._elapsed;
    _lastPaintElapsed = old._lastPaintElapsed;
    _lastSize = old._lastSize;
    if (old.dropList.isEmpty) return;
    dropSize = Size(dropWidth, dropHeight);
    paintObject = Paint()
      ..color = dropColors[0]
      ..style = PaintingStyle.fill;
    dropList = old.dropList;
    if (dropList.length > numberOfDrops) {
      dropList.removeRange(numberOfDrops, dropList.length);
    }
    // Missing drops are added on the next paint, which knows the canvas size.
    for (final Drop drop in dropList) {
      if (drop.dropLayer >= numberOfLayers) {
        drop.dropLayer = random.nextInt(numberOfLayers);
      }
      if (!dropColors.contains(drop.dropColor)) {
        drop.dropColor = dropColors[random.nextInt(dropColors.length)];
      }
      final double scale = 1 + drop.dropLayer * distanceBetweenLayers;
      drop.drop = Rect.fromLTWH(drop.drop.left, drop.drop.top,
          dropSize.width * scale, dropSize.height * scale);
      drop.dropSpeed = dropFallSpeed * scale;
    }
  }

  /// Gives [drop] a random x position, layer and color. Its top is at [top], or just above the
  /// canvas if [top] is null.
  void _respawn(Drop drop, Size size, {double? top}) {
    final double x = random.nextDouble() * size.width;
    final int layer =
        random.nextInt(numberOfLayers); // 0 is the layer furthest behind
    final double scale = 1 + layer * distanceBetweenLayers;
    final double height = dropSize.height * scale;
    drop.drop =
        Rect.fromLTWH(x, top ?? -height, dropSize.width * scale, height);
    drop.dropSpeed = dropFallSpeed * scale;
    drop.dropLayer = layer;
    drop.dropColor = dropColors[random.nextInt(dropColors.length)];
  }

  /// Moves the drops from a canvas of [oldSize] to one of [size], keeping their relative
  /// positions. On an axis that had no extent, drops are scattered randomly instead.
  void _resize(Size oldSize, Size size) {
    for (final Drop drop in dropList) {
      final double left = oldSize.width > 0
          ? drop.drop.left * size.width / oldSize.width
          : random.nextDouble() * size.width;
      final double top = oldSize.height > 0
          ? drop.drop.top * size.height / oldSize.height
          : random.nextDouble() * size.height;
      drop.drop = Rect.fromLTWH(left, top, drop.drop.width, drop.drop.height);
    }
  }

  /// How many reference frames the drops move in this paint.
  double _framesSinceLastPaint() {
    final Duration? elapsed = _elapsed;
    if (elapsed == null) return 1;
    final Duration? last = _lastPaintElapsed;
    _lastPaintElapsed = elapsed;
    if (last == null) return 1;
    final double frames =
        (elapsed - last).inMicroseconds / _referenceFrame.inMicroseconds;
    return frames.clamp(0.0, _maxFramesPerPaint);
  }

  Paint _paintFor(Drop drop) {
    final List<Paint?> byLayer = _paints.putIfAbsent(
        drop.dropColor, () => List<Paint?>.filled(numberOfLayers, null));
    final int layer = drop.dropLayer;
    return byLayer[layer] ??= _createPaint(drop);
  }

  Paint _createPaint(Drop drop) {
    final Color color = drop.dropColor
        .withAlpha((255.0 * (drop.dropLayer + 1) / numberOfLayers).round());
    if (!trail) {
      return Paint()
        ..color = color
        ..style = PaintingStyle.fill;
    }
    return Paint()
      ..shader = LinearGradient(
        stops: [trailStartFraction, 1.0],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, const Color(0x00000000)],
      ).createShader(Offset.zero & drop.drop.size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Size? lastSize = _lastSize;
    if (lastSize != null && lastSize != size) _resize(lastSize, size);
    _lastSize = size;
    if (dropList.length < numberOfDrops) {
      initialize(canvas, size);
    }
    final double frames = _framesSinceLastPaint();
    for (int i = 0; i < numberOfDrops; i++) {
      final Drop drop = dropList[i];
      final double distance = drop.dropSpeed * frames;
      if (drop.drop.top + distance < size.height) {
        drop.drop = drop.drop.translate(0, distance);
      } else {
        _respawn(drop, size);
      }

      // draw drop
      final Paint paint = _paintFor(drop);
      if (trail) {
        canvas.save();
        canvas.translate(drop.drop.left, drop.drop.top);
        canvas.drawRect(Offset.zero & drop.drop.size, paint);
        canvas.restore();
      } else {
        canvas.drawRect(drop.drop, paint);
      }
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
