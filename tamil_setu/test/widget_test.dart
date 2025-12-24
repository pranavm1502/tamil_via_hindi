import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/main.dart';

void main() {
  testWidgets('Tamil Setu app launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TamilSetuApp());

    // Verify that the app bar title is present
    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);

    // Verify that at least one lesson is displayed
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Dashboard shows curriculum lessons', (WidgetTester tester) async {
    await tester.pumpWidget(const TamilSetuApp());

    // Verify that lesson titles are present
    expect(find.textContaining('1. Basics'), findsOneWidget);
    expect(find.textContaining('2. Pronouns'), findsOneWidget);

    // Verify navigation icon is present
    expect(find.byIcon(Icons.arrow_forward_ios), findsWidgets);
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TamilSetuApp());

    // Tap on the first lesson
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    // Verify we're on the lesson screen
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });
}
