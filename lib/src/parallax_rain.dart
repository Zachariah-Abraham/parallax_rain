import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

/// The default drop color, Material's `Colors.greenAccent`. The package doesn't import the Material
/// library.
const Color _greenAccent = Color(0xFF69F0AE);

/// Create a cool 3D rain effect!
class ParallaxRain extends StatefulWidget {
  const ParallaxRain({
    Key? key,
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
    this.trail = false,
    this.angle = 0,
    this.alignment,
    this.reducedMotion,
  }) : assert(numberOfLayers >= 1, "The minimum number of layers is 1"),
       assert(
         angle > -pi / 2 && angle < pi / 2,
         "The angle must be between -pi / 2 and pi / 2 (exclusive)",
       ),
       assert(
         distanceBetweenLayers > 0,
         "The distance between layers cannot be 0, try setting the number of layers to 1 instead",
       ),
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

  /// Tilt of the fall direction from straight down, in radians. Positive angles make the drops fall
  /// towards the right, negative ones towards the left, and the drops are drawn along their path.
  /// For example `pi / 12` is 15 degrees. [dropFallSpeed] is the speed along the path. It must be
  /// between -pi / 2 and pi / 2 (exclusive). Defaults to 0, straight down.
  final double angle;

  /// How [child] is positioned inside the rain area. When it is null (the default), the child gets
  /// the incoming constraints and the rain is as big as the child. When it is set, the rain fills
  /// the space the parent allows (if bounded) and the child is aligned inside it.
  final AlignmentGeometry? alignment;

  /// Whether the rain is held still. The drops stay where they are, and nothing is repainted
  /// while this is true.
  ///
  /// When null (the default), it follows the device: the rain stops when the user has asked the
  /// system for reduced motion (`MediaQueryData.disableAnimations`). Pass false to keep the rain
  /// moving regardless, or true to hold it still regardless.
  ///
  /// Set a [dropFallSpeed] of 0 to freeze the rain too. The animation is stopped then as well.
  final bool? reducedMotion;

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
  bool _reduceMotion = false;

  /// Whether the rain moves: not while the fall speed is 0, nor when the user asked for reduced
  /// motion (see [ParallaxRain.reducedMotion]).
  bool get _shouldAnimate =>
      widget.dropFallSpeed != 0 && !(widget.reducedMotion ?? _reduceMotion);

  /// Starts or stops the ticker to match [_shouldAnimate]. A stopped ticker costs nothing: the
  /// rain isn't repainted at all.
  void _syncTicker() {
    final Ticker ticker = _ticker ??= createTicker(_onTick);
    final bool animate = _shouldAnimate;
    parallaxRainPainter._frozen = !animate;
    if (animate == ticker.isActive) return;
    if (animate) {
      ticker.start();
    } else {
      ticker.stop();
    }
  }

  /// Starts the animation. It starts automatically, so there's no need to call this.
  @Deprecated(
    'The animation starts automatically. This will be removed in a future release.',
  )
  void runAnimation() => _syncTicker();

  void _onTick(Duration elapsed) {
    parallaxRainPainter._elapsed = elapsed;
    notifier.value = !notifier.value;
  }

  @override
  void initState() {
    super.initState();
    _assertSettings();
    parallaxRainPainter = _createPainter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not MediaQuery.of: it asserts when there is no MediaQuery, and nullOk/maybeOf aren't available
    // on every supported Flutter version.
    _reduceMotion =
        context
            .dependOnInheritedWidgetOfExactType<MediaQuery>()
            ?.data
            .disableAnimations ??
        false;
    _syncTicker();
  }

  /// Checks what a const constructor can't.
  void _assertSettings() {
    assert(
      widget.dropColors.isNotEmpty,
      "The drop colors list cannot be empty",
    );
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
      angle: widget.angle,
      notifier: notifier,
    );
  }

  @override
  void didUpdateWidget(ParallaxRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assertSettings();
    final ParallaxRain w = widget;
    if (w.numberOfDrops != oldWidget.numberOfDrops ||
        w.dropFallSpeed != oldWidget.dropFallSpeed ||
        w.numberOfLayers != oldWidget.numberOfLayers ||
        w.dropHeight != oldWidget.dropHeight ||
        w.dropWidth != oldWidget.dropWidth ||
        !listEquals(w.dropColors, oldWidget.dropColors) ||
        w.trailStartFraction != oldWidget.trailStartFraction ||
        w.distanceBetweenLayers != oldWidget.distanceBetweenLayers ||
        w.angle != oldWidget.angle ||
        w.trail != oldWidget.trail) {
      // A new painter with the new settings takes over the drops, so the rain doesn't reset.
      parallaxRainPainter = _createPainter().._takeOver(parallaxRainPainter);
    }
    _syncTicker();
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
        child: Container(alignment: widget.alignment, child: widget.child),
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

  /// Tilt of the fall direction from straight down, in radians. See [ParallaxRain.angle].
  final double angle;
  late final ValueNotifier notifier;
  Random random = Random();

  /// Animation time, set by [ParallaxRainState] every frame. While it is null (when the painter is
  /// used on its own), drops move one reference frame per paint.
  Duration? _elapsed;
  Duration? _lastPaintElapsed;

  /// Set by [ParallaxRainState] while the animation is stopped: paints don't move the drops.
  bool _frozen = false;

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
    this.angle = 0,
    required this.notifier,
  }) : _sin = sin(angle),
       _cos = cos(angle),
       super(repaint: notifier);

  /// The fall direction, a unit vector (sin, cos) of [angle].
  final double _sin;
  final double _cos;

  /// Scatters drops randomly over the canvas until there are [numberOfDrops].
  void initialize(Canvas canvas, Size size) {
    paintObject =
        Paint()
          ..color = dropColors[0]
          ..style = PaintingStyle.fill;
    dropSize = Size(dropWidth, dropHeight);
    while (dropList.length < numberOfDrops) {
      // Keeping [widget.numberOfLayers] layers for the parallax effect, the base values are for the layer furthest behind
      final drop = Drop(
        drop: Rect.zero,
        dropSpeed: 0,
        dropLayer: 0,
        dropColor: dropColors[0],
      );
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
    paintObject =
        Paint()
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
      drop.drop = Rect.fromLTWH(
        drop.drop.left,
        drop.drop.top,
        dropSize.width * scale,
        dropSize.height * scale,
      );
      drop.dropSpeed = dropFallSpeed * scale;
    }
  }

  /// Gives [drop] a random x position, layer and color. Its top is at [top], or just above the
  /// canvas if [top] is null. A drop that starts above the canvas can be left of or right of it,
  /// so that the tilted rain still reaches every part of the canvas.
  void _respawn(Drop drop, Size size, {double? top}) {
    double minX = 0;
    double maxX = size.width;
    if (top == null) {
      final double drift = size.height * _sin / _cos;
      minX = min(0, -drift);
      maxX = max(size.width, size.width - drift);
    }
    final double x = minX + random.nextDouble() * (maxX - minX);
    final int layer = random.nextInt(
      numberOfLayers,
    ); // 0 is the layer furthest behind
    final double scale = 1 + layer * distanceBetweenLayers;
    final double height = dropSize.height * scale;
    drop.drop = Rect.fromLTWH(
      x,
      top ?? -height,
      dropSize.width * scale,
      height,
    );
    drop.dropSpeed = dropFallSpeed * scale;
    drop.dropLayer = layer;
    drop.dropColor = dropColors[random.nextInt(dropColors.length)];
  }

  /// Moves the drops from a canvas of [oldSize] to one of [size], keeping their relative
  /// positions. On an axis that had no extent, drops are scattered randomly instead.
  void _resize(Size oldSize, Size size) {
    for (final Drop drop in dropList) {
      final double left =
          oldSize.width > 0
              ? drop.drop.left * size.width / oldSize.width
              : random.nextDouble() * size.width;
      final double top =
          oldSize.height > 0
              ? drop.drop.top * size.height / oldSize.height
              : random.nextDouble() * size.height;
      drop.drop = Rect.fromLTWH(left, top, drop.drop.width, drop.drop.height);
    }
  }

  /// How many reference frames the drops move in this paint.
  double _framesSinceLastPaint() {
    if (_frozen) return 0;
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
      drop.dropColor,
      () => List<Paint?>.filled(numberOfLayers, null),
    );
    final int layer = drop.dropLayer;
    return byLayer[layer] ??= _createPaint(drop);
  }

  Paint _createPaint(Drop drop) {
    final Color color = drop.dropColor.withAlpha(
      (255.0 * (drop.dropLayer + 1) / numberOfLayers).round(),
    );
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
      final Rect moved = drop.drop.translate(distance * _sin, distance * _cos);
      // A tilted drop is also gone when it has left through the side it falls towards.
      final double margin = drop.drop.height * _sin.abs();
      if (moved.top < size.height &&
          !(_sin > 0 && moved.left >= size.width + margin) &&
          !(_sin < 0 && moved.right <= -margin)) {
        drop.drop = moved;
      } else {
        _respawn(drop, size);
      }

      // draw drop
      final Paint paint = _paintFor(drop);
      if (_sin != 0) {
        // Rotate around the center of the drop, so that its length follows its path.
        final Rect rect = drop.drop;
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(-angle);
        canvas.translate(-rect.width / 2, -rect.height / 2);
        canvas.drawRect(Offset.zero & rect.size, paint);
        canvas.restore();
      } else if (trail) {
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
