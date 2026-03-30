import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/models/word_pair.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/screens/quiz_view.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
  });

  Widget buildQuizView(List<WordPair> words) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ProgressProvider(testingModeOverride: true)),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => MistakeProvider()),
      ],
      child: MaterialApp(
        home: QuizView(
          words: words,
          lessonIndex: 0,
        ),
      ),
    );
  }

  group('QuizView — image cue', () {
    final wordWithImage = WordPair(
      hindi: 'नमस्ते',
      tamil: 'வணக்கம்',
      pronunciation: 'वणक्कम्',
      audioPath: 'assets/audio/l1_namaste.mp3',
      imagePath: 'assets/images/words/namaste.png',
    );

    final wordWithoutImage = WordPair(
      hindi: 'धन्यवाद',
      tamil: 'நன்றி',
      pronunciation: 'नन्ऱि',
      audioPath: 'assets/audio/l1_thanks.mp3',
    );

    testWidgets('shows Image widget before reveal when word has imagePath',
        (tester) async {
      await tester.pumpWidget(buildQuizView([wordWithImage]));
      await tester.pump();

      // Consume expected asset-not-found error from test environment
      tester.takeException();

      // Contextual image should be visible (identified by key)
      expect(find.byKey(const ValueKey('flashcard-word-image')), findsOneWidget);
      final image = tester.widget<Image>(
          find.byKey(const ValueKey('flashcard-word-image')));
      expect(image.semanticLabel, 'नमस्ते');
    });

    testWidgets('image remains visible after reveal', (tester) async {
      await tester.pumpWidget(buildQuizView([wordWithImage]));
      await tester.pump();
      tester.takeException();

      // Tap "Show Answer"
      await tester.tap(find.text('Show Answer'));
      await tester.pump();
      tester.takeException();

      // Image should still be in the tree after reveal
      expect(find.byKey(const ValueKey('flashcard-word-image')), findsOneWidget);
    });

    testWidgets('no contextual image before reveal when word has no imagePath',
        (tester) async {
      await tester.pumpWidget(buildQuizView([wordWithoutImage]));
      await tester.pump();

      expect(find.byKey(const ValueKey('flashcard-word-image')), findsNothing);
    });
  });
}
