import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/main.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'package:tamil_setu/models/lesson.dart'; // Added for Lesson type
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'test_helpers.dart';
import 'firebase_mock.dart';

void main() {
  setupFirebaseMocks();

  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Mock Data for the Dashboard
  final List<Lesson> testLessons = [
    Lesson(
      level: 1,
      title: 'Basics (Greet)',
      description: 'Learn basic welcomes',
      words: [],
    ),
  ];

  // Mock Platform Channels for non-Firebase services
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (c) async => 1);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'), (c) async => 1);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (c) async => '.');

  Widget createTestableApp() {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(auth: null, googleSignIn: null)),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // FIX: Inject the mock lessons so Cards and Icons actually render
        ChangeNotifierProvider(
            create: (_) =>
                ContentProvider()..setLessonsForTesting(testLessons)),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: const TamilSetuApp(),
    );
  }

  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableApp());

    await waitForLoader(tester);

    // This will now find 1 widget because we provided testLessons
    expect(find.text('Tamil Setu (हिंदी ➡️ தமிழ்)'), findsOneWidget);
    expect(find.byType(Card), findsAtLeastNWidgets(1));
  });

  testWidgets('Dashboard shows correct lesson titles and icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableApp());

    await waitForLoader(tester);

    // This will now find the play icons on our test lesson tile
    expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableApp());

    await waitForLoader(tester);

    // Tap the lesson tile by title (ensures we hit the correct card)
    final lessonTitleFinder = find.text('Basics (Greet)');
    final lessonTileFinder = find.ancestor(
      of: lessonTitleFinder,
      matching: find.byType(InkWell),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.ensureVisible(lessonTitleFinder);
    await tester.tap(lessonTileFinder);

    // Wait for navigation animation
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('MCQ'), findsOneWidget);
  });
}
