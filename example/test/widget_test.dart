import 'package:flutter_test/flutter_test.dart';
import 'package:parallax_rain/parallax_rain.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('shows four rain variants and the setState counter works',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(ParallaxRain), findsNWidgets(4));
    expect(
        find.text('Multicolor with setState (press here): 0'), findsOneWidget);

    await tester.tap(find.textContaining('Multicolor with setState'));
    await tester.pump();

    expect(
        find.text('Multicolor with setState (press here): 1'), findsOneWidget);
  });
}
