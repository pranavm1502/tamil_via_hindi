import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/main.dart';

// Import the helper file to access 'makeTestableWidget'
import 'test_helpers.dart'; 

void main() {
  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    // 1. Build the app using the wrapper to inject Providers
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));

    // 2. CRITICAL: Wait for the JSON to load and the FutureBuilder/Provider to rebuild the UI
    await tester.pumpAndSettle();

    // 3. Verify the App Bar title
    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);

    // 4. Verify that lessons are displayed
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Dashboard shows correct lesson titles and icons',
      (WidgetTester tester) async {
    // 1. Build the app with Providers
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    
    await tester.pumpAndSettle(); // Wait for data load

    // 5. Update expectations to match 'master_content.json' titles
    expect(find.text('Basics (Greet)'), findsOneWidget);
    expect(find.text('Pronouns'), findsOneWidget);

    // 6. Verify status icons are present
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    // 1. Build the app with Providers
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    
    await tester.pumpAndSettle(); // Wait for data load

    // 7. Tap on the first lesson
    await tester.tap(find.text('Basics (Greet)'));
    
    // 8. Wait for the navigation animation to complete
    await tester.pumpAndSettle();

    // 9. Verify we are on the Lesson Screen
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget); 
    expect(find.text('MCQ'), findsOneWidget);
  });
}