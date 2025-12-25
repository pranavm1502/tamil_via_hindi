import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/lesson.dart'; // Import Lesson model
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
      ChangeNotifierProvider(
        create: (_) => ProgressProvider()..loadProgress(),
      ),
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