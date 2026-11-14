import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallax_rain/parallax_rain.dart';

Widget _app(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

CustomPaint _rainPaint(WidgetTester tester) => tester.widget<CustomPaint>(
  find.descendant(
    of: find.byType(ParallaxRain),
    matching: find.byType(CustomPaint),
  ),
);

ParallaxRainState _state(WidgetTester tester) =>
    tester.state<ParallaxRainState>(find.byType(ParallaxRain));

/// A canvas that only records the rotations. Everything else is ignored.
class _RotationRecorder implements Canvas {
  final List<double> rotations = <double>[];

  @override
  void rotate(double radians) => rotations.add(radians);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('builds with defaults and scatters drops on first paint', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SizedBox.expand(child: ParallaxRain())));

    final ParallaxRainPainter painter = _state(tester).parallaxRainPainter;
    expect(painter.dropList, hasLength(200));
    for (final Drop drop in painter.dropList) {
      expect(drop.dropLayer, inInclusiveRange(0, 2));
      expect(drop.dropColor, const Color(0xFF69F0AE));
    }
  });

  testWidgets('rainIsInBackground selects painter or foregroundPainter', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ParallaxRain(child: Text('child'))));
    expect(_rainPaint(tester).painter, isA<ParallaxRainPainter>());
    expect(_rainPaint(tester).foregroundPainter, isNull);

    await tester.pumpWidget(
      _app(
        ParallaxRain(
          key: UniqueKey(),
          rainIsInBackground: false,
          child: const Text('child'),
        ),
      ),
    );
    expect(_rainPaint(tester).painter, isNull);
    expect(_rainPaint(tester).foregroundPainter, isA<ParallaxRainPainter>());
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('drops move with elapsed time', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox.expand(
          child: ParallaxRain(numberOfDrops: 50, numberOfLayers: 1),
        ),
      ),
    );
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    await tester.pump(const Duration(milliseconds: 16));
    final List<double> before = [for (final d in drops) d.drop.top];

    // A default drop (speed 1, one layer) moves 1 pixel per 60 fps frame. Pump whole
    // milliseconds: older test bindings (Flutter 2.0) round the ticker time to milliseconds.
    const Duration step = Duration(milliseconds: 50);
    await tester.pump(step);
    final double expected = step.inMicroseconds / 16667;
    for (int i = 0; i < drops.length; i++) {
      final double moved = drops[i].drop.top - before[i];
      // Respawned drops jump back above the top.
      if (moved >= 0) expect(moved, closeTo(expected, 0.01));
    }
  });

  testWidgets('a parent rebuild does not reset the drops', (tester) async {
    late StateSetter setOuterState;
    int counter = 0;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setOuterState = setState;
            return SizedBox.expand(
              child: ParallaxRain(child: Text('$counter')),
            );
          },
        ),
      ),
    );
    final ParallaxRainState state = _state(tester);
    final List<Drop> drops = state.parallaxRainPainter.dropList;

    setOuterState(() => counter++);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(_state(tester), same(state));
    expect(_state(tester).parallaxRainPainter.dropList, same(drops));
    expect(drops, hasLength(200));
  });

  testWidgets('new settings apply to the existing drops without resetting them', (
    tester,
  ) async {
    Widget rain({int drops = 50, int layers = 3, List<Color>? colors}) => _app(
      SizedBox.expand(
        child: ParallaxRain(
          numberOfDrops: drops,
          numberOfLayers: layers,
          dropColors: colors ?? const [_red],
        ),
      ),
    );
    await tester.pumpWidget(rain());
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    final List<Offset> positions = [for (final d in drops) d.drop.topLeft];

    await tester.pumpWidget(rain(layers: 1, colors: const [_blue]));
    final ParallaxRainPainter painter = _state(tester).parallaxRainPainter;
    expect(painter.numberOfLayers, 1);
    expect(painter.dropList, same(drops));
    for (int i = 0; i < drops.length; i++) {
      // The rebuild paints once, which moves each drop by at most one frame. Respawned drops
      // jump back above the top.
      final double moved = drops[i].drop.top - positions[i].dy;
      if (moved >= 0) {
        expect(moved, lessThanOrEqualTo(3.01));
        expect(drops[i].drop.left, positions[i].dx);
      }
      expect(drops[i].dropLayer, 0);
      expect(drops[i].dropColor, _blue);
      expect(drops[i].drop.width, closeTo(1, 1e-9));
      expect(drops[i].drop.height, closeTo(20, 1e-9));
      expect(drops[i].dropSpeed, 1);
    }

    await tester.pumpWidget(rain(drops: 80, layers: 1));
    expect(_state(tester).parallaxRainPainter.dropList, hasLength(80));
    await tester.pumpWidget(rain(drops: 10, layers: 1));
    expect(_state(tester).parallaxRainPainter.dropList, hasLength(10));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drops move along when the size changes', (tester) async {
    Widget rain(double width, double height) => _app(
      Center(
        child: SizedBox(
          width: width,
          height: height,
          child: const ParallaxRain(numberOfDrops: 50),
        ),
      ),
    );
    await tester.pumpWidget(rain(200, 100));
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    final List<double> lefts = [for (final d in drops) d.drop.left];
    final List<double> tops = [for (final d in drops) d.drop.top];

    await tester.pumpWidget(rain(800, 400));
    expect(_state(tester).parallaxRainPainter.dropList, same(drops));
    for (int i = 0; i < drops.length; i++) {
      final double top = drops[i].drop.top;
      // Respawned drops jump back above the top. The others keep their relative position, and
      // the rebuild's paint moves them down by at most three frames (the front layer).
      if (top < 0) continue;
      expect(drops[i].drop.left, closeTo(lefts[i] * 4, 1e-6));
      expect(top - tops[i] * 4, inInclusiveRange(0, 3.01));
    }
  });

  Widget motionApp({
    required bool reduceMotion,
    double speed = 1,
    bool? override,
  }) => _app(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: SizedBox.expand(
        child: ParallaxRain(
          numberOfDrops: 50,
          numberOfLayers: 1,
          dropFallSpeed: speed,
          reducedMotion: override,
        ),
      ),
    ),
  );

  List<double> tops(WidgetTester tester) => [
    for (final d in _state(tester).parallaxRainPainter.dropList) d.drop.top,
  ];

  testWidgets('reduced motion stops the rain but still shows the drops', (
    tester,
  ) async {
    await tester.pumpWidget(motionApp(reduceMotion: true));
    expect(tester.binding.transientCallbackCount, 0);
    expect(_state(tester).parallaxRainPainter.dropList, hasLength(50));

    final List<double> before = tops(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tops(tester), before);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reducedMotion: false keeps the rain moving', (tester) async {
    await tester.pumpWidget(motionApp(reduceMotion: true, override: false));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('reducedMotion: true holds the rain still', (tester) async {
    await tester.pumpWidget(motionApp(reduceMotion: false, override: true));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('the rain stops and resumes with the reduced motion setting', (
    tester,
  ) async {
    await tester.pumpWidget(motionApp(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(motionApp(reduceMotion: true));
    expect(tester.binding.transientCallbackCount, 0);
    final List<double> frozen = tops(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tops(tester), frozen);

    await tester.pumpWidget(motionApp(reduceMotion: false));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pump();
    final List<double> before = tops(tester);
    await tester.pump(const Duration(milliseconds: 50));
    const double expected = 50000 / 16667;
    int moving = 0;
    for (int i = 0; i < before.length; i++) {
      final double moved = tops(tester)[i] - before[i];
      // Respawned drops jump back above the top.
      if (moved >= 0) {
        expect(moved, closeTo(expected, 0.01));
        moving++;
      }
    }
    expect(moving, greaterThan(0));
  });

  testWidgets('a fall speed of 0 stops the animation until it is raised', (
    tester,
  ) async {
    await tester.pumpWidget(motionApp(reduceMotion: false, speed: 0));
    expect(tester.binding.transientCallbackCount, 0);
    final List<double> before = tops(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tops(tester), before);

    await tester.pumpWidget(motionApp(reduceMotion: false, speed: 1));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tops(tester), isNot(before));
  });

  Widget angledApp(double angle, {int drops = 50, double speed = 1}) => _app(
    Center(
      child: SizedBox(
        width: 600,
        height: 400,
        child: ParallaxRain(
          numberOfDrops: drops,
          numberOfLayers: 1,
          dropFallSpeed: speed,
          angle: angle,
        ),
      ),
    ),
  );

  for (final double angle in [pi / 6, -pi / 6]) {
    testWidgets('a drop falls along an angle of $angle', (tester) async {
      await tester.pumpWidget(angledApp(angle));
      final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
      await tester.pump(const Duration(milliseconds: 16));
      final List<Offset> before = [for (final d in drops) d.drop.topLeft];

      await tester.pump(const Duration(milliseconds: 50));
      const double distance = 50000 / 16667;
      int moving = 0;
      for (int i = 0; i < drops.length; i++) {
        final Offset moved = drops[i].drop.topLeft - before[i];
        // Respawned drops jump to a new place.
        if (moved.dy <= 0 || moved.dy > distance) continue;
        expect(moved.dx, closeTo(distance * sin(angle), 0.01));
        expect(moved.dy, closeTo(distance * cos(angle), 0.01));
        moving++;
      }
      expect(moving, greaterThan(0));
    });
  }

  testWidgets('tilted rain still covers the side it falls away from', (
    tester,
  ) async {
    await tester.pumpWidget(angledApp(pi / 6, drops: 1000, speed: 5));
    // Let the drops that started above the area reach the bottom.
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    // The lower left corner is only reached by drops that started left of the area.
    final int corner =
        drops.where((d) => d.drop.left < 50 && d.drop.top > 300).length;
    expect(corner, greaterThan(0));
  });

  testWidgets('drops are drawn along their angle', (tester) async {
    List<double> rotations(ParallaxRainPainter painter) {
      final _RotationRecorder canvas = _RotationRecorder();
      painter.paint(canvas, const Size(600, 400));
      return canvas.rotations;
    }

    await tester.pumpWidget(angledApp(pi / 6, drops: 5));
    expect(
      rotations(_state(tester).parallaxRainPainter),
      everyElement(-pi / 6),
    );
    expect(rotations(_state(tester).parallaxRainPainter), hasLength(5));

    await tester.pumpWidget(angledApp(0, drops: 5));
    expect(rotations(_state(tester).parallaxRainPainter), isEmpty);
  });

  testWidgets('changing the angle keeps the drops', (tester) async {
    await tester.pumpWidget(angledApp(0));
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    await tester.pumpWidget(angledApp(pi / 6));
    expect(_state(tester).parallaxRainPainter.angle, pi / 6);
    expect(_state(tester).parallaxRainPainter.dropList, same(drops));
  });

  test('an angle of a quarter turn or more is rejected', () {
    expect(() => ParallaxRain(angle: pi / 2), throwsAssertionError);
    expect(() => ParallaxRain(angle: -pi / 2), throwsAssertionError);
    expect(const ParallaxRain(angle: pi / 3).angle, pi / 3);
  });

  testWidgets('can be a const widget', (tester) async {
    const Widget rain = SizedBox.expand(child: ParallaxRain(numberOfDrops: 10));
    await tester.pumpWidget(_app(rain));
    await tester.pumpWidget(_app(rain));
    expect(_state(tester).parallaxRainPainter.dropList, hasLength(10));
  });

  testWidgets('an empty list of drop colors is rejected', (tester) async {
    await tester.pumpWidget(_app(const ParallaxRain(dropColors: [])));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('works inside Row and Column (unbounded constraints)', (
    tester,
  ) async {
    // Not const: the Flutter SDK's own Row/Column asserts can't be evaluated at compile time.
    await tester.pumpWidget(
      _app(
        // ignore: prefer_const_constructors, prefer_const_literals_to_create_immutables
        Column(
          children: [
            // ignore: prefer_const_constructors
            Row(children: const [ParallaxRain(child: Text('row'))]),
            const ParallaxRain(child: Text('column')),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('row'), findsOneWidget);
    expect(find.text('column'), findsOneWidget);
  });

  testWidgets('disposing stops the animation', (tester) async {
    await tester.pumpWidget(_app(const ParallaxRain(child: Text('rain'))));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(_app(const SizedBox()));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('does not change the child semantics or hit testing', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _app(
        ParallaxRain(
          rainIsInBackground: false,
          child: GestureDetector(onTap: () => taps++, child: const Text('tap')),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    expect(taps, 1);
  });

  testWidgets('alignment places the child inside the rain area', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            height: 100,
            child: ParallaxRain(
              alignment: Alignment.bottomRight,
              child: SizedBox(key: Key('c'), width: 20, height: 10),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ParallaxRain)), const Size(200, 100));
    expect(
      tester.getBottomRight(find.byKey(const Key('c'))),
      const Offset(200, 100),
    );
  });

  testWidgets('without alignment the rain is as big as the child', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Align(
          alignment: Alignment.topLeft,
          child: ParallaxRain(child: SizedBox(width: 20, height: 10)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ParallaxRain)), const Size(20, 10));
  });
}
