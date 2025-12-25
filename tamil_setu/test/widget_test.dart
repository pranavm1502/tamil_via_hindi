import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:tamil_setu/main.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Mock Platform Channels
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (c) async => 1);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '.');

  testWidgets('Tamil Setu app launches and loads dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));

    // ✅ App Start: Wait for the Spinner to go away
    await waitForLoader(tester);

    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Dashboard shows correct lesson titles and icons', (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    
    // ✅ App Start: Wait for the Spinner to go away
    await waitForLoader(tester);

    expect(find.text('Basics (Greet)'), findsOneWidget);
    expect(find.text('Pronouns'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    
    // ✅ App Start: Wait for the Spinner to go away
    await waitForLoader(tester);

    // 👆 Now we are on the dashboard. Tap the card.
    await tester.tap(find.text('Basics (Greet)'));

    // ✅ NAVIGATION FIX: Use pumpAndSettle here!
    // Why? Because we are waiting for a "Slide Transition" animation, not a loading spinner.
    await tester.pumpAndSettle();
    
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('MCQ'), findsOneWidget);
  });
}
//   testWidgets('DEBUG: Check what is stuck on screen', (WidgetTester tester) async {
//   // 1. Build app
//   await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));

//   // 2. Instead of 'pumpAndSettle' (which crashes), just wait 2 seconds
//   await tester.pump(const Duration(seconds: 2));

//   // 3. Print what is currently visible
//   if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
//     print("🚨 DEBUG: App is STUCK showing a CircularProgressIndicator (Loading Spinner)");
//   } else if (find.byType(ErrorWidget).evaluate().isNotEmpty) {
//     print("🚨 DEBUG: App crashed with an internal error (ErrorWidget visible)");
//   } else {
//     print("🚨 DEBUG: App seems to have loaded. Found widgets: ${find.byType(Card).evaluate().length} Cards");
//   }
// });
// }
