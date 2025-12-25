import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:tamil_setu/main.dart';
import 'test_helpers.dart';

void main() {
  // 1. Initialize bindings
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2. Mock Shared Preferences (Critical for your app)
  SharedPreferences.setMockInitialValues({});

  // 3. Mock Flutter TTS (New Syntax)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_tts'),
    (MethodCall methodCall) async {
      return 1; // Return success
    },
  );

  // 4. Mock AudioPlayers (New Syntax)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async {
      return 1; // Return success
    },
  );

  // 5. Mock PathProvider (New Syntax)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      return '.'; // Return a fake dot path
    },
  );

  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    // Note: Ensure your makeTestableWidget in test_helpers.dart
    // uses the "..loadContent()" fix we discussed!
    await tester.pumpWidget(makeTestableWidget(child: const TamilSetuApp()));

    // Wait for the JSON load and spinner to finish
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
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('MCQ'), findsOneWidget);
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
}
