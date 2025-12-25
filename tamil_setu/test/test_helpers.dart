import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/models/lesson.dart';
import 'package:tamil_setu/models/word_pair.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates mock lesson data for testing
List<Lesson> _createMockLessons() {
  return [
    Lesson(
      level: 1,
      title: 'Basics (Greet)',
      description: 'Start with Namaste and basic questions.',
      words: [
        WordPair(
          hindi: 'नमस्ते',
          tamil: 'வணக்கம்',
          pronunciation: 'वणक्कम्',
          audioPath: 'assets/audio/l1_namaste.mp3',
        ),
        WordPair(
          hindi: 'धन्यवाद',
          tamil: 'நன்றி',
          pronunciation: 'नऩ्ऱि',
          audioPath: 'assets/audio/l1_dhanyavaad.mp3',
        ),
      ],
    ),
    Lesson(
      level: 2,
      title: 'Pronouns',
      description: 'Me, You, This, That',
      words: [
        WordPair(
          hindi: 'मैं',
          tamil: 'நான்',
          pronunciation: 'नाऩ्',
          audioPath: 'assets/audio/l2_main.mp3',
        ),
        WordPair(
          hindi: 'तुम',
          tamil: 'நீ',
          pronunciation: 'नी',
          audioPath: 'assets/audio/l2_tum.mp3',
        ),
      ],
    ),
  ];
}

Widget makeTestableWidget({required Widget child}) {
  // Create a ContentProvider with pre-loaded mock data for testing
  final contentProvider = ContentProvider();
  contentProvider.setLessonsForTesting(_createMockLessons());

  return MultiProvider(
    providers: [
      // 1. Trigger loadProgress immediately
      ChangeNotifierProvider(
        create: (_) => ProgressProvider()..loadProgress(),
      ),

      // 2. Trigger initialize immediately
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..initialize(),
      ),

      // 3. Use pre-loaded ContentProvider to avoid asset loading in tests
      ChangeNotifierProvider.value(
        value: contentProvider,
      ),
    ],
    child: child,
  );
}

Future<void> waitForLoader(WidgetTester tester) async {
  // 1. Pump once to start the animation
  await tester.pump();

  // 2. Loop for up to 5 seconds waiting for the spinner to vanish
  bool loaderExists = true;
  for (int i = 0; i < 50; i++) {
    // 50 * 100ms = 5 seconds
    // Check if the spinner is still on screen
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      loaderExists = false;
      break;
    }
    // Advance time by 100ms to let the spinner spin and Future complete
    await tester.pump(const Duration(milliseconds: 100));
  }

  // 3. If it's still there after 5 seconds, throw a clear error
  if (loaderExists) {
    throw Exception(
        '🚨 TEST FAILED: The Loading Spinner never disappeared. Check your JSON loader or Provider logic.');
  }

  // 4. Once the spinner is gone, we can safely settle (for navigation animations etc)
  await tester.pumpAndSettle();
}
