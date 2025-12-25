import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/lesson.dart'; // Import Lesson model
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';

Widget makeTestableWidget({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ProgressProvider()..loadProgress(),
      ),
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..initialize(),
      ),
      // ✅ FIX: Use MockContentProvider instead of the real one
      // This bypasses 'rootBundle' and loads data instantly.
      ChangeNotifierProvider<ContentProvider>(
        create: (_) => MockContentProvider()..loadContent(),
      ),
    ],
    child: child,
  );
}

Future<void> waitForLoader(WidgetTester tester) async {
  await tester.pump(); // Start animation

  bool loaderExists = true;
  // Wait up to 5 seconds
  for (int i = 0; i < 50; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      loaderExists = false;
      break;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  if (loaderExists) {
    throw Exception(
        '🚨 TEST FAILED: The Loading Spinner never disappeared. The Provider failed to set isLoading=false.');
  }

  await tester.pumpAndSettle();
}

// ✅ NEW: A Mock Provider that skips the File System
class MockContentProvider extends ContentProvider {
  // We need internal storage since we can't access the private _lessons from the parent
  List<Lesson> _testLessons = [];
  bool _testLoading = true;

  @override
  List<Lesson> get lessons => _testLessons;

  @override
  bool get isLoading => _testLoading;

  @override
  Future<void> loadContent() async {
    // 1. Start loading
    _testLoading = true;
    notifyListeners();

    // 2. Simulate a tiny delay (optional, mimics real life)
    await Future.delayed(const Duration(milliseconds: 10));

    // 3. Inject Dummy Data that matches your test expectations
    //    (Matches 'master_content.json')
    _testLessons = [
      Lesson(
        level: 1,
        title: "Basics (Greet)",
        description: "Learn to say hello",
        words: [], // Empty words list is fine for Dashboard tests
      ),
      Lesson(
        level: 2,
        title: "Pronouns",
        description: "I, You, We",
        words: [],
      ),
    ];

    // 4. Finish loading
    _testLoading = false;
    notifyListeners();
  }
}