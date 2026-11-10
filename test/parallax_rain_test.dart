import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallax_rain/parallax_rain.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

CustomPaint _rainPaint(WidgetTester tester) => tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ParallaxRain),
        matching: find.byType(CustomPaint),
      ),
    );

ParallaxRainState _state(WidgetTester tester) =>
    tester.state<ParallaxRainState>(find.byType(ParallaxRain));

void main() {
  testWidgets('builds with defaults and scatters drops on first paint',
      (tester) async {
    await tester.pumpWidget(_app(SizedBox.expand(child: ParallaxRain())));

    final ParallaxRainPainter painter = _state(tester).parallaxRainPainter;
    expect(painter.dropList, hasLength(200));
    for (final Drop drop in painter.dropList) {
      expect(drop.dropLayer, inInclusiveRange(0, 2));
      expect(drop.dropColor, Colors.greenAccent);
    }
  });

  testWidgets('rainIsInBackground selects painter or foregroundPainter',
      (tester) async {
    await tester.pumpWidget(_app(ParallaxRain(child: const Text('child'))));
    expect(_rainPaint(tester).painter, isA<ParallaxRainPainter>());
    expect(_rainPaint(tester).foregroundPainter, isNull);

    await tester.pumpWidget(_app(ParallaxRain(
      key: UniqueKey(),
      rainIsInBackground: false,
      child: const Text('child'),
    )));
    expect(_rainPaint(tester).painter, isNull);
    expect(_rainPaint(tester).foregroundPainter, isA<ParallaxRainPainter>());
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('drops move with elapsed time', (tester) async {
    await tester.pumpWidget(_app(SizedBox.expand(
      child: ParallaxRain(numberOfDrops: 50, numberOfLayers: 1),
    )));
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
    await tester.pumpWidget(_app(StatefulBuilder(builder: (context, setState) {
      setOuterState = setState;
      return SizedBox.expand(
        child: ParallaxRain(child: Text('$counter')),
      );
    })));
    final ParallaxRainState state = _state(tester);
    final List<Drop> drops = state.parallaxRainPainter.dropList;

    setOuterState(() => counter++);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(_state(tester), same(state));
    expect(_state(tester).parallaxRainPainter.dropList, same(drops));
    expect(drops, hasLength(200));
  });

  testWidgets('new settings apply to the existing drops without resetting them',
      (tester) async {
    Widget rain({int drops = 50, int layers = 3, List<Color>? colors}) =>
        _app(SizedBox.expand(
          child: ParallaxRain(
            numberOfDrops: drops,
            numberOfLayers: layers,
            dropColors: colors ?? const [Colors.red],
          ),
        ));
    await tester.pumpWidget(rain());
    final List<Drop> drops = _state(tester).parallaxRainPainter.dropList;
    final List<Offset> positions = [for (final d in drops) d.drop.topLeft];

    await tester.pumpWidget(rain(layers: 1, colors: const [Colors.blue]));
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
      expect(drops[i].dropColor, Colors.blue);
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
    Widget rain(double width, double height) => _app(Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ParallaxRain(numberOfDrops: 50),
          ),
        ));
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

  testWidgets('works inside Row and Column (unbounded constraints)',
      (tester) async {
    await tester.pumpWidget(_app(Column(children: [
      Row(children: [ParallaxRain(child: const Text('row'))]),
      ParallaxRain(child: const Text('column')),
    ])));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('row'), findsOneWidget);
    expect(find.text('column'), findsOneWidget);
  });

  testWidgets('disposing stops the animation', (tester) async {
    await tester.pumpWidget(_app(ParallaxRain(child: const Text('rain'))));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(_app(const SizedBox()));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('does not change the child semantics or hit testing',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(_app(ParallaxRain(
      rainIsInBackground: false,
      child: TextButton(onPressed: () => taps++, child: const Text('tap')),
    )));

    await tester.tap(find.text('tap'));
    expect(taps, 1);
  });
}
