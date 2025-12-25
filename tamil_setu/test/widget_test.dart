import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/main.dart';

void main() {
  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    // 1. Build the app
    await tester.pumpWidget(const TamilSetuApp());

    // 2. CRITICAL: Wait for the JSON to load and the FutureBuilder/Provider to rebuild the UI
    //    'pumpAndSettle' waits for all animations and async tasks to finish.
    await tester.pumpAndSettle();

    // 3. Verify the App Bar title
    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);

    // 4. Verify that lessons are displayed (The Dashboard uses GridView with Cards)
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Dashboard shows correct lesson titles and icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TamilSetuApp());
    await tester.pumpAndSettle(); // Wait for data load

    // 5. Update expectations to match 'master_content.json' titles
    //    Old: "1. Basics" -> New: "Basics (Greet)"
    expect(find.text('Basics (Greet)'), findsOneWidget);
    expect(find.text('Pronouns'), findsOneWidget);

    // 6. Verify status icons are present
    //    The arrow icon was removed. Level 1 is unlocked, so it shows 'play_arrow'.
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TamilSetuApp());
    await tester.pumpAndSettle(); // Wait for data load

    // 7. Tap on the first lesson (Basics)
    //    We find it by the text in the card.
    await tester.tap(find.text('Basics (Greet)'));
    
    // 8. Wait for the navigation animation to complete
    await tester.pumpAndSettle();

    // 9. Verify we are on the Lesson Screen by checking the Tabs
    expect(find.text('Learn'), findsOneWidget);
    // Note: The tab name was changed from 'Quiz' to 'Flashcards' in your LessonScreen
    expect(find.text('Flashcards'), findsOneWidget); 
    expect(find.text('MCQ'), findsOneWidget);
  });
}