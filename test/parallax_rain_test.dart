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
