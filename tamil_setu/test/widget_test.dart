import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Add this import
import 'package:flutter/services.dart';
import 'package:tamil_setu/main.dart';
import 'test_helpers.dart';

void main() {
  // 2. Initialize bindings
  TestWidgetsFlutterBinding.ensureInitialized();

  // 3. CRITICAL FIX: Mock Shared Preferences so the app doesn't hang waiting for storage
  SharedPreferences.setMockInitialValues({});

  // 4. Mock Flutter TTS
  const MethodChannel('flutter_tts')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return 1;
  });

  // 5. Mock AudioPlayers
  const MethodChannel('xyz.luan/audioplayers')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return 1;
  });

  // 6. Mock PathProvider
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return '.';
  });

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
  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    await tester.pumpAndSettle();

    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Dashboard shows correct lesson titles and icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    await tester.pumpAndSettle();

    expect(find.text('Basics (Greet)'), findsOneWidget);
    expect(find.text('Pronouns'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Basics (Greet)'));
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    // Ensure this matches the actual text in your app (Flashcards vs Quiz)
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('MCQ'), findsOneWidget);
  });
}
