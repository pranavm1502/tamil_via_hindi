import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/models/word_pair.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/screens/multiple_choice_quiz.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
  });

  // All 4 words have images so the test is reliable regardless of shuffle order.
  final wordsAllWithImages = [
    WordPair(
      hindi: 'नमस्ते',
      tamil: 'வணக்கம்',
      pronunciation: 'वणक्कम्',
      audioPath: 'assets/audio/l1_namaste.mp3',
      imagePath: 'assets/images/words/namaste.png',
    ),
    WordPair(
      hindi: 'धन्यवाद',
      tamil: 'நன்றி',
      pronunciation: 'नन्ऱि',
      audioPath: 'assets/audio/l1_thanks.mp3',
      imagePath: 'assets/images/words/dhanyavaad.png',
    ),
    WordPair(
      hindi: 'हाँ',
      tamil: 'ஆமாம்',
      pronunciation: 'आमाम्',
      audioPath: 'assets/audio/l1_yes.mp3',
      imagePath: 'assets/images/words/haan.png',
    ),
    WordPair(
      hindi: 'नहीं',
      tamil: 'இல்லை',
      pronunciation: 'इल्लै',
      audioPath: 'assets/audio/l1_no.mp3',
      imagePath: 'assets/images/words/nahin.png',
    ),
  ];

  // All 4 words have no images.
  final wordsNoImages = wordsAllWithImages.map((w) => WordPair(
    hindi: w.hindi,
    tamil: w.tamil,
    pronunciation: w.pronunciation,
    audioPath: w.audioPath,
  )).toList();

  Widget buildMCQ(List<WordPair> words) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ProgressProvider(testingModeOverride: true)),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => MistakeProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MultipleChoiceQuiz(
            words: words,
            lessonIndex: 0,
          ),
        ),
      ),
    );
  }

  group('MultipleChoiceQuiz — image prompt', () {
    testWidgets('shows Image widget with Hindi prompt when word has imagePath',
        (tester) async {
      await tester.pumpWidget(buildMCQ(wordsAllWithImages));
      await tester.pump();

      // Consume expected asset-not-found error(s) from test environment
      tester.takeException();

      // Contextual image present (identified by key)
      expect(find.byKey(const ValueKey('mcq-word-image')), findsOneWidget);
      final image = tester.widget<Image>(
          find.byKey(const ValueKey('mcq-word-image')));
      expect(image.semanticLabel, isNotNull);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('no contextual image widget when no words have imagePath',
        (tester) async {
      await tester.pumpWidget(buildMCQ(wordsNoImages));
      await tester.pump();

      expect(find.byKey(const ValueKey('mcq-word-image')), findsNothing);
    });
  });
}

