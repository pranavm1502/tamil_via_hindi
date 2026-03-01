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
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/providers/sentence_provider.dart';
import 'package:tamil_setu/providers/privacy_provider.dart';
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

  Future<Widget> createTestableApp() async {
    final mockAuth = MockFirebaseAuth();
    final privacy = PrivacyProvider();
    await privacy.completeOnboarding(birthYear: 2000);
    await privacy.completeAdultConsent(
      trackingAllowed: true,
      socialEnabled: true,
      notificationsEnabled: true,
    );
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(auth: mockAuth, googleSignIn: null)),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // FIX: Inject the mock lessons so Cards and Icons actually render
        ChangeNotifierProvider(
            create: (_) =>
                ContentProvider()..setLessonsForTesting(testLessons)),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => MistakeProvider()),
        ChangeNotifierProvider(create: (_) => SentenceProvider()),
        ChangeNotifierProvider.value(value: privacy),
      ],
      child: const TamilSetuApp(),
    );
  }

  testWidgets('Tamil Setu app launches and loads dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(await createTestableApp());

    await waitForLoader(tester);

    // This will now find 1 widget because we provided testLessons
    expect(find.text('Tamil Setu (Hindi -> Tamil)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick Review'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quick Review'), findsOneWidget);
  });

  testWidgets('Dashboard shows correct lesson titles and icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(await createTestableApp());

    await waitForLoader(tester);

    // This will now find the play icons on our test lesson tile
    await tester.scrollUntilVisible(
      find.byIcon(Icons.play_arrow),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
  });

  testWidgets('Can navigate to lesson screen', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestableApp());

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
    expect(find.text('Build'), findsOneWidget);
  });
}
