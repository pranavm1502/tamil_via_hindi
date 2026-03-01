import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/widgets/peacock_mascot.dart';

void main() {
  testWidgets('PeacockMascot animates in when enabled for tests',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PeacockMascot(
            message: 'Hello!',
            enableTestAnimation: true,
          ),
        ),
      ),
    );

    final mascotFinder = find.byType(PeacockMascot);
    final opacityFinder = find.descendant(
      of: mascotFinder,
      matching: find.byType(Opacity),
    );

    final initialOpacity = tester.widget<Opacity>(opacityFinder.first).opacity;
    expect(initialOpacity, lessThan(1.0));

    await tester.pump(const Duration(milliseconds: 200));
    final midOpacity = tester.widget<Opacity>(opacityFinder.first).opacity;
    expect(midOpacity, greaterThan(initialOpacity));
    expect(midOpacity, lessThan(1.0));

    await tester.pump(const Duration(milliseconds: 800));
    final endOpacity = tester.widget<Opacity>(opacityFinder.first).opacity;
    expect(endOpacity, closeTo(1.0, 0.01));
  });
}
