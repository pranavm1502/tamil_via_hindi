import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/models/checkpoint.dart';
import 'package:tamil_setu/models/lesson.dart';
import 'package:tamil_setu/models/word_pair.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/sentence_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/screens/checkpoint_quiz_screen.dart';
import 'package:tamil_setu/screens/dashboard_screen.dart';
import 'package:tamil_setu/screens/lesson_screen.dart';
import 'package:tamil_setu/screens/mistakes_review_screen.dart';
import 'package:tamil_setu/screens/review_screen.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'package:tamil_setu/theme.dart';
import 'package:tamil_setu/widgets/peacock_mascot.dart';
import 'package:tamil_setu/widgets/streak_widget.dart';
import '../firebase_mock.dart';

void main() {
  setUpAll(() async {
    setupFirebaseMocks();
    SharedPreferences.setMockInitialValues({});

    final hindiFont =
        rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final hindiLoader = FontLoader('NotoSansDevanagari')..addFont(hindiFont);
    await hindiLoader.load();

    final tamilFont = rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf');
    final tamilLoader = FontLoader('NotoSansTamil')..addFont(tamilFont);
    await tamilLoader.load();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (m) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (m) async => null);
    messenger.setMockMessageHandler(
        'xyz.luan/audioplayers.global/events', (m) async => null);
  });

  const tablet7 = ScreenshotDevice(
    platform: TargetPlatform.android,
    resolution: Size(1200, 1920),
    pixelRatio: 2.0,
    goldenSubFolder: 'sevenInchScreenshots/',
    frameBuilder: ScreenshotFrame.androidTablet,
  );

  const tablet10 = ScreenshotDevice(
    platform: TargetPlatform.android,
    resolution: Size(1600, 2560),
    pixelRatio: 2.0,
    goldenSubFolder: 'tenInchScreenshots/',
    frameBuilder: ScreenshotFrame.androidTablet,
  );

  final deviceMap = {
    'phone': GoldenScreenshotDevices.androidPhone.device,
    'tablet7': tablet7,
    'tablet10': tablet10,
  };

  final mockLessons = [
    Lesson(
      level: 1,
      title: 'Basics (Greet)',
      description: 'Learn basic welcomes',
      words: [
        WordPair(
            hindi: 'नमस्ते',
            tamil: 'வணக்கம்',
            pronunciation: 'Vanakkam',
            audioPath: 'assets/audio/one.mp3'),
        WordPair(
            hindi: 'धन्यवाद',
            tamil: 'நன்றி',
            pronunciation: 'Nandri',
            audioPath: 'assets/audio/two.mp3'),
        WordPair(
            hindi: 'कहाँ',
            tamil: 'எங்கே',
            pronunciation: 'Engae',
            audioPath: 'assets/audio/three.mp3'),
        WordPair(
            hindi: 'कब',
            tamil: 'எப்போது',
            pronunciation: 'Eppodhu',
            audioPath: 'assets/audio/four.mp3'),
      ],
    ),
    Lesson(
      level: 2,
      title: 'Pronouns',
      description: 'Me, You, We',
      words: [
        WordPair(
            hindi: 'मैं',
            tamil: 'நான்',
            pronunciation: 'Naan',
            audioPath: 'assets/audio/main.mp3'),
        WordPair(
            hindi: 'तुम',
            tamil: 'நீ',
            pronunciation: 'Nee',
            audioPath: 'assets/audio/tum.mp3'),
      ],
    ),
    Lesson(
      level: 3,
      title: 'Colors',
      description: 'Red, Blue, and Green',
      words: [
        WordPair(
            hindi: 'लाल',
            tamil: 'சிவப்பு',
            pronunciation: 'Sivappu',
            audioPath: 'assets/audio/red.mp3'),
        WordPair(
            hindi: 'नीला',
            tamil: 'நீலம்',
            pronunciation: 'Neelam',
            audioPath: 'assets/audio/blue.mp3'),
        WordPair(
            hindi: 'हरा',
            tamil: 'பச்சை',
            pronunciation: 'Pachai',
            audioPath: 'assets/audio/green.mp3'),
        WordPair(
            hindi: 'पीला',
            tamil: 'மஞ்சள்',
            pronunciation: 'Manjal',
            audioPath: 'assets/audio/yellow.mp3'),
      ],
    ),
  ];

  final checkpoint = Checkpoint(
    checkpointNumber: 1,
    title: 'Checkpoint 1',
    description: 'Review Quiz for Foundation Skills',
    startLessonIndex: 0,
    endLessonIndex: 2,
    questionCount: 6,
    passingScore: 80,
  );

  deviceMap.forEach((deviceName, device) {
    group('Capturing $deviceName', () {
      testGoldens('1_Dashboard', (tester) async {
        await _takeAppScreenshot(tester, device, '1_dashboard',
            const DashboardScreen(), mockLessons);
      });

      testGoldens('2_Review', (tester) async {
        await _takeAppScreenshot(
            tester, device, '2_review', const ReviewScreen(), mockLessons);
      });

      testGoldens('3_Quiz', (tester) async {
        final lesson = mockLessons.first;
        await _takeAppScreenshot(
          tester,
          device,
          '3_quiz',
          LessonScreen(lesson: lesson, lessonIndex: 0),
          mockLessons,
        );
      });

      testGoldens('4_Checkpoint', (tester) async {
        await _takeAppScreenshot(
          tester,
          device,
          '4_checkpoint',
          CheckpointQuizScreen(checkpoint: checkpoint),
          mockLessons,
        );
      });
    });
  });
}

Future<ReviewProvider> _prepareReviewProvider(
  List<Lesson> mockLessons, {
  bool startSession = false,
}) async {
  final provider = ReviewProvider();
  await provider.clearAllReviewData();
  await provider.loadReviewCards();
  if (mockLessons.isNotEmpty) {
    await provider.createCardsForLesson(0, mockLessons.first.words.length);
    await provider.loadReviewCards();
    if (startSession) {
      provider.startReviewSession();
    }
  }
  return provider;
}

Future<void> _takeAppScreenshot(
  WidgetTester tester,
  ScreenshotDevice device,
  String fileName,
  Widget screen,
  List<Lesson> mockLessons,
) async {
  final reviewProvider = await _prepareReviewProvider(
    mockLessons,
    startSession: screen is ReviewScreen,
  );

  final contentProvider = ContentProvider();
  contentProvider.setLessonsForTesting(mockLessons);

  final mockUser = MockUser();
  final mockAuth = MockFirebaseAuth(mockUser);

  final wrappedWidget = StreamProvider<User?>.value(
    value: Stream.value(mockUser),
    initialData: mockUser,
    child: MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(auth: mockAuth, googleSignIn: null)),
        ChangeNotifierProvider.value(value: contentProvider),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: reviewProvider),
        ChangeNotifierProvider(create: (_) => MistakeProvider()..loadMistakes()),
        ChangeNotifierProvider(
          create: (_) => SentenceProvider()..loadSentences(),
        ),
      ],
      child: Theme(
        data: ThemeData(
          primaryColor: Colors.orange,
          fontFamily: 'NotoSansDevanagari',
          fontFamilyFallback: const ['NotoSansTamil'],
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
        ),
        child: Material(
          child: _injectStreakWidget(screen),
        ),
      ),
    ),
  );

  await tester.pumpWidget(ScreenshotApp(device: device, home: wrappedWidget));
  await _waitForStableFrame(tester);
  await tester.expectScreenshot(device, fileName);
}

Widget _injectStreakWidget(Widget screen) {
  if (screen is DashboardScreen) {
    return const DashboardScreenWithInjectedStreak();
  }
  return screen;
}

Future<void> _waitForStableFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 400));
}

class DashboardScreenWithInjectedStreak extends StatelessWidget {
  const DashboardScreenWithInjectedStreak({super.key});

  @override
  Widget build(BuildContext context) {
    final contentProvider = context.watch<ContentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamil Setu (Hindi -> Tamil)'),
        centerTitle: true,
        elevation: 2,
        actions: const [],
      ),
      body: contentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                const Color(0xFF0F1A1F),
                                const Color(0xFF0B1418),
                                PeacockTheme.peacockBlue.withAlpha(18),
                              ]
                            : [
                                PeacockTheme.softCream,
                                PeacockTheme.softCream.withAlpha(230),
                                PeacockTheme.peacockGreen.withAlpha(22),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -120,
                  right: -80,
                  child: _OrnamentCircle(
                    size: 220,
                    color: PeacockTheme.peacockBlue.withAlpha(18),
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -60,
                  child: _OrnamentCircle(
                    size: 260,
                    color: PeacockTheme.deepTeal.withAlpha(20),
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PeacockTheme.peacockBlue.withAlpha(18),
                                PeacockTheme.peacockGreen.withAlpha(18),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: PeacockTheme.peacockBlue.withAlpha(50),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(14),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const PeacockMascot(
                            message: 'Hello! Ready to learn Tamil today?',
                            imageSize: 150,
                            fontSize: 17,
                            bubblePadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            layout: MascotLayout.overlap,
                            overlapInset: 140,
                            imageOffset: Offset(14, 10),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: StreakWidget(
                          streakOverride: 3,
                          freezesOverride: 1,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _TodayPlanCard(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _DailyGoalCard(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _QuickActions(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ProgressHeader(
                          totalLessons: contentProvider.lessons.length),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: _SectionHeader(
                          title: 'Lessons',
                          subtitle: 'Start where you left off',
                        ),
                      ),
                    ),
                    _LessonsAndCheckpointsBuilder(
                      lessons: contentProvider.lessons,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _OrnamentCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _OrnamentCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final isSignedIn = user != null;
    final mistakeCount = context.watch<MistakeProvider>().mistakeCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            PeacockTheme.peacockBlue.withAlpha(22),
            PeacockTheme.peacockGreen.withAlpha(26),
          ],
        ),
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReviewScreen()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Quick Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: mistakeCount == 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MistakesReviewScreen(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    mistakeCount == 0
                        ? 'Mistakes'
                        : 'Mistakes ($mistakeCount)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSignedIn
                ? () => Navigator.pushNamed(context, '/leaderboard')
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign in to view the leaderboard.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.leaderboard),
            label: const Text('Leaderboard'),
          ),
          if (!isSignedIn) ...[
            const SizedBox(height: 8),
            Text(
              'Sign in to appear on leaderboards and sync your streaks.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: PeacockTheme.peacockBlue.withAlpha(140),
          ),
        ),
      ],
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard();

  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewProvider>();
    final mistakes = context.watch<MistakeProvider>();
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();

    final dueNow = review.dueCardCount;
    final mistakeCount = mistakes.mistakeCount;
    final nextLessonIndex = _findNextLesson(content.lessons, progress);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Plan",
                  style: Theme.of(context).textTheme.titleMedium),
              Text('3 tasks', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Finish one task to keep momentum.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _PlanRow(
            icon: Icons.auto_awesome,
            title: 'Review due cards',
            subtitle: dueNow == 0
                ? 'No cards due right now'
                : '$dueNow card${dueNow == 1 ? '' : 's'} due now',
            actionLabel: 'Review',
            enabled: dueNow > 0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReviewScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _PlanRow(
            icon: Icons.refresh,
            title: 'Fix mistakes',
            subtitle: mistakeCount == 0
                ? 'No mistakes to revisit'
                : '$mistakeCount to review',
            actionLabel: 'Practice',
            enabled: mistakeCount > 0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MistakesReviewScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _PlanRow(
            icon: Icons.play_arrow,
            title: 'Continue lesson',
            subtitle: nextLessonIndex == null
                ? 'All lessons completed'
                : content.lessons[nextLessonIndex].title,
            actionLabel: 'Start',
            enabled: nextLessonIndex != null,
            onPressed: () {
              if (nextLessonIndex == null) return;
              final lesson = content.lessons[nextLessonIndex];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonScreen(
                    lesson: lesson,
                    lessonIndex: nextLessonIndex,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int? _findNextLesson(List<Lesson> lessons, ProgressProvider progress) {
    for (var i = 0; i < lessons.length; i++) {
      if (!progress.isLessonLocked(i) && !progress.isLessonCompleted(i)) {
        return i;
      }
    }
    return null;
  }
}

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  const _PlanRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: PeacockTheme.peacockBlue.withAlpha(12),
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: PeacockTheme.peacockBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: enabled
                ? FilledButton(
                    onPressed: onPressed,
                    child: Text(actionLabel),
                  )
                : OutlinedButton(
                    onPressed: null,
                    child: Text(actionLabel),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewProvider>();
    final goal = review.dailyGoalCards;
    final reviewed = review.cardsReviewedToday;
    final progress = goal == 0 ? 0.0 : (reviewed / goal).clamp(0.0, 1.0);
    final nextReview = review.nextReviewAt;
    final dueNow = review.dueCardCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Goal',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('$reviewed / $goal',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
            color: PeacockTheme.peacockGreen,
            backgroundColor: PeacockTheme.peacockBlue.withAlpha(24),
          ),
          const SizedBox(height: 8),
          Text(
            nextReview == null
                ? 'No upcoming reviews scheduled.'
                : 'Next review: ${_formatNextReview(nextReview)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Due now: $dueNow card${dueNow == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatNextReview(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    if (diff.inMinutes <= 0) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'in ${diff.inHours} hr';
    }
    return 'on ${dateTime.month}/${dateTime.day}';
  }
}

class _ProgressHeader extends StatelessWidget {
  final int totalLessons;
  const _ProgressHeader({required this.totalLessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final completedCount = progress.totalCompletedLessons;
        final overallProgress = progress.getOverallProgress(totalLessons);

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Your Progress',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$completedCount/$totalLessons levels'),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalLessons == 0 ? 0 : completedCount / totalLessons,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('${overallProgress.toStringAsFixed(0)}% Complete'),
            ],
          ),
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final int index;
  const _LessonTile({required this.lesson, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final isLocked = progress.isLessonLocked(index);
        final isCompleted = progress.isLessonCompleted(index);
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isLocked
            ? Theme.of(context).cardColor.withAlpha(179)
            : isCompleted
                ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                : (isDark ? Colors.orange.shade900 : Colors.orange.shade50);

        return Card(
          elevation: isLocked ? 0 : 4,
          color: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLocked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Complete previous levels to unlock!')));
                  }
                : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LessonScreen(
                                lesson: lesson, lessonIndex: index)));
                  },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isLocked
                        ? Colors.grey
                        : (isCompleted ? Colors.green : Colors.orange),
                    child: Icon(
                        isLocked
                            ? Icons.lock
                            : (isCompleted ? Icons.check : Icons.play_arrow),
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(lesson.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(lesson.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LessonsAndCheckpointsBuilder extends StatelessWidget {
  final List<Lesson> lessons;
  const _LessonsAndCheckpointsBuilder({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final checkpoints = CheckpointService.generateCheckpoints(lessons.length);
    final List<Widget> items = [];

    int i = 0;
    while (i < lessons.length) {
      final List<Widget> rowChildren = [];

      rowChildren.add(
        Expanded(
          child: SizedBox(
            height: 180,
            child: _LessonTile(lesson: lessons[i], index: i),
          ),
        ),
      );

      final bool shouldAddCheckpoint =
          (i + 1) % CheckpointService.lessonsPerSection == 0;

      if (i + 1 < lessons.length && !shouldAddCheckpoint) {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(
          Expanded(
            child: SizedBox(
              height: 180,
              child: _LessonTile(lesson: lessons[i + 1], index: i + 1),
            ),
          ),
        );
        i += 2;
      } else {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
        i += 1;
      }

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );

      if (shouldAddCheckpoint) {
        final checkpointIndex = i ~/ CheckpointService.lessonsPerSection - 1;
        if (checkpointIndex < checkpoints.length) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _CheckpointTile(checkpoint: checkpoints[checkpointIndex]),
            ),
          );
        }
      }
    }

    return SliverList(
      delegate: SliverChildListDelegate(items),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final Checkpoint checkpoint;
  const _CheckpointTile({required this.checkpoint});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final isLocked =
            progress.isCheckpointLocked(checkpoint.checkpointNumber);
        final isCompleted =
            progress.isCheckpointCompleted(checkpoint.checkpointNumber);

        return Card(
          elevation: isLocked ? 0 : 6,
          color: isCompleted
              ? Colors.purple.shade50
              : (isLocked ? Colors.grey.shade200 : Colors.purple.shade100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCompleted
                  ? Colors.purple
                  : (isLocked ? Colors.grey : Colors.purple.shade300),
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLocked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Complete all lessons in this section first!'),
                      ),
                    );
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CheckpointQuizScreen(checkpoint: checkpoint),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock
                        : (isCompleted ? Icons.check_circle : Icons.flag),
                    size: 48,
                    color: isLocked ? Colors.grey : Colors.purple,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              checkpoint.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified,
                                  color: Colors.purple, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint.lessonRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isLocked ? Colors.grey : Colors.purple,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
