import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:provider/provider.dart';

// Ensure these match your project structure
import 'package:tamil_setu/screens/dashboard_screen.dart';
import 'package:tamil_setu/screens/lesson_screen.dart';
import 'package:tamil_setu/models/lesson.dart';
import 'package:tamil_setu/models/word_pair.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // 1. Load Fonts for rendering Hindi and Tamil correctly
    final hindiFont = rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final hindiLoader = FontLoader('NotoSansDevanagari')..addFont(hindiFont);
    await hindiLoader.load();

    final tamilFont = rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf');
    final tamilLoader = FontLoader('NotoSansTamil')..addFont(tamilFont);
    await tamilLoader.load();
    
    // 2. Mock Audio and Binary Messaging
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (m) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (m) async => null);
    messenger.setMockMessageHandler('xyz.luan/audioplayers.global/events', (m) async => null);
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

  // Mock Data to inject into ContentProvider
  final mockLessons = [
  Lesson(
    level: 1,
    title: 'Greetings',
    description: 'Learn basic welcomes',
    words: [
      WordPair(hindi: 'नमस्ते', tamil: 'வணக்கம்', pronunciation: 'Vanakkam', audioPath: 'assets/audio/vanakkam.mp3'),
    ],
  ),
  Lesson(
    level: 2,
    title: 'Numbers',
    description: 'Learn counting 1-10',
    words: [
      WordPair(hindi: 'एक', tamil: 'ஒன்று', pronunciation: 'Ondru', audioPath: 'assets/audio/one.mp3'),
    ],
  ),
  Lesson(
    level: 3,
    title: 'Colors',
    description: 'Red, Blue, and Green',
    words: [
       WordPair(hindi: 'लाल', tamil: 'சிவப்பு', pronunciation: 'Sivappu', audioPath: 'assets/audio/red.mp3'),
    ],
  ),
  ];

  deviceMap.forEach((deviceName, device) {
    group('Capturing $deviceName', () {
      testGoldens('1_Dashboard', (tester) async {
        await _takeAppScreenshot(tester, device, '1_dashboard', const DashboardScreen(), mockLessons);
      });

      testGoldens('2_Lesson_Learn', (tester) async {
        await _takeAppScreenshot(tester, device, '2_learn', LessonScreen(lesson: mockLessons[0], lessonIndex: 0), mockLessons);
      });
      
      // ... (Rest of your celebration/thinking tests)
    });
  });
}

Future<void> _takeAppScreenshot(
  WidgetTester tester, 
  ScreenshotDevice device, 
  String fileName, 
  Widget screen, 
  List<Lesson> mockLessons
) async {
  // 3. Initialize Providers with pre-loaded data to bypass "isLoading" states
  final contentProvider = ContentProvider();
  contentProvider.setLessonsForTesting(mockLessons); // Bypass loading loop

  final wrappedWidget = MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: contentProvider),
      ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: Theme(
      data: ThemeData(
        primaryColor: Colors.orange,
        // Match your font names exactly as registered in FontLoader
        fontFamilyFallback: const ['NotoSansDevanagari', 'NotoSansTamil'],
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.orange),
      ),
      child: Material(child: screen),
    ),
  );

  await tester.pumpWidget(ScreenshotApp(device: device, home: wrappedWidget));

  // 4. Manual Pumping to avoid the "pumpAndSettle timed out" error
  await tester.loadAssets(); 
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  
  // Final wait for mascot entry/fade animations
  await tester.pumpFrames(find.byType(ScreenshotApp).evaluate().first.widget, const Duration(seconds: 1));

  await tester.expectScreenshot(device, fileName);
}