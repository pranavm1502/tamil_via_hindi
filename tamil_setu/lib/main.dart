import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/content_provider.dart';
import 'providers/review_provider.dart';
import 'providers/mistake_provider.dart';
import 'providers/sentence_provider.dart';
import 'providers/privacy_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme.dart'; // 1. Import your newly created theme file
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/privacy_onboarding_screen.dart';
import 'screens/privacy_consent_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For FirebaseFirestore
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await AnalyticsService().initialize(coldStart: true);

    await NotificationService().initialize();

    const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
    if (kDebugMode && useEmulator) {
      // 10.0.2.2 is the magic IP for Android Emulators to see your Mac
      await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      debugPrint('Using Firebase Emulator Suite');
    }

    // Initialize providers
    final progressProvider = ProgressProvider();
    final themeProvider = ThemeProvider();
    final contentProvider = ContentProvider();
    final reviewProvider = ReviewProvider();
    final mistakeProvider = MistakeProvider();
    final sentenceProvider = SentenceProvider();
    final privacyProvider = PrivacyProvider();
    final authService = AuthService();

    AnalyticsService().bindUserStream(authService.userStream);

    // Load persistent data (Progress, Themes, Lesson Content, and Review Cards)
    await Future.wait([
      progressProvider.loadProgress(),
      themeProvider.initialize(),
      contentProvider.loadContent(),
      reviewProvider.loadReviewCards(),
      mistakeProvider.loadMistakes(),
      sentenceProvider.loadSentences(),
      privacyProvider.load(),
    ]);

    AnalyticsService().setTrackingEnabled(privacyProvider.trackingAllowed);
    privacyProvider.addListener(() {
      AnalyticsService().setTrackingEnabled(privacyProvider.trackingAllowed);
      if (!privacyProvider.notificationsEnabled) {
        // ignore: discarded_futures
        reviewProvider.disableReminders();
      }
    });

    runApp(
      StreamProvider<User?>.value(
        value: authService.userStream,
        initialData: null,
        child: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: authService),
            ChangeNotifierProvider.value(value: progressProvider),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: contentProvider),
            ChangeNotifierProvider.value(value: reviewProvider),
            ChangeNotifierProvider.value(value: mistakeProvider),
            ChangeNotifierProvider.value(value: sentenceProvider),
            ChangeNotifierProvider.value(value: privacyProvider),
          ],
          child: const TamilSetuApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Startup error: $e');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(error: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;
  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Setu',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PeacockTheme.softCream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Startup failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TamilSetuApp extends StatelessWidget {
  const TamilSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here to rebuild the app when the user toggles Light/Dark mode
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Tamil Setu',
          debugShowCheckedModeBanner: false,
          theme: PeacockTheme.lightTheme,
          darkTheme: PeacockTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          navigatorObservers: [AnalyticsService().observer],
          home: Consumer<PrivacyProvider>(
            builder: (context, privacyProvider, child) {
              if (!privacyProvider.onboardingComplete) {
                return const PrivacyOnboardingScreen();
              }
              if (!privacyProvider.childMode &&
                  !privacyProvider.consentComplete) {
                return const PrivacyConsentScreen();
              }
              return const DashboardScreen();
            },
          ),
          routes: {
            '/leaderboard': (context) => const LeaderboardScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
