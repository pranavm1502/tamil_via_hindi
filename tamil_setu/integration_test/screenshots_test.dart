import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/main.dart' as app;
import 'package:tamil_setu/models/checkpoint.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/screens/checkpoint_quiz_screen.dart';
import 'package:tamil_setu/screens/multiple_choice_quiz.dart';
import 'package:tamil_setu/screens/review_screen.dart';
import 'package:tamil_setu/widgets/peacock_mascot.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture Play Store screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await _waitForLoadToFinish(tester);

    await binding.takeScreenshot('1_dashboard');

    final context = tester.element(find.byType(app.TamilSetuApp));
    final contentProvider =
        Provider.of<ContentProvider>(context, listen: false);
    final reviewProvider =
        Provider.of<ReviewProvider>(context, listen: false);

    await _ensureLessonsLoaded(tester, contentProvider);

    await reviewProvider.clearAllReviewData();
    await reviewProvider
        .createCardsForLesson(0, contentProvider.lessons.first.words.length);
    reviewProvider.startReviewSession();

    await _pushScreen(
      tester,
      _navigatorContext(tester),
      const ReviewScreen(),
    );
    await binding.takeScreenshot('2_review');
    await _popScreen(tester, _navigatorContext(tester));

    await _pushScreen(
      tester,
      _navigatorContext(tester),
      MultipleChoiceQuiz(
        words: contentProvider.lessons.first.words,
        lessonIndex: 0,
      ),
    );
    await binding.takeScreenshot('3_quiz');
    await _popScreen(tester, _navigatorContext(tester));

    final checkpoint = Checkpoint(
      checkpointNumber: 1,
      title: 'Checkpoint 1',
      description: 'Review Quiz for Foundation Skills',
      startLessonIndex: 0,
      endLessonIndex: 2,
      questionCount: 6,
      passingScore: 80,
    );

    await _pushScreen(
      tester,
      _navigatorContext(tester),
      CheckpointQuizScreen(checkpoint: checkpoint),
    );
    await binding.takeScreenshot('4_checkpoint');
  });
}

Future<void> _waitForLoadToFinish(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));

  for (int i = 0; i < 30; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  await tester.pumpAndSettle();
}

Future<void> _ensureLessonsLoaded(
  WidgetTester tester,
  ContentProvider contentProvider,
) async {
  for (int i = 0; i < 30; i++) {
    if (contentProvider.lessons.isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pushScreen(
  WidgetTester tester,
  BuildContext context,
  Widget screen,
) async {
  final wrappedScreen = _wrapForMaterial(screen);
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => wrappedScreen));
  await tester.pumpAndSettle();
  await _dismissOverlays(tester);
}

Future<void> _popScreen(WidgetTester tester, BuildContext context) async {
  Navigator.of(context).pop();
  await tester.pumpAndSettle();
}

Future<void> _dismissOverlays(WidgetTester tester) async {
  final mascotFinder = find.byType(PeacockMascot);
  if (mascotFinder.evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

BuildContext _navigatorContext(WidgetTester tester) {
  return tester.element(find.byType(Navigator));
}

Widget _wrapForMaterial(Widget screen) {
  if (screen is MultipleChoiceQuiz) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: screen,
    );
  }
  return screen;
}
