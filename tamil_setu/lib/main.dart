import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/content_provider.dart';
import 'providers/review_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme.dart'; // 1. Import your newly created theme file
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For FirebaseFirestore
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized for async data loading
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
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
  final authService = AuthService();

  // Load persistent data (Progress, Themes, Lesson Content, and Review Cards) before the app starts
  await Future.wait([
    progressProvider.loadProgress(),
    themeProvider.initialize(),
    contentProvider.loadContent(),
    reviewProvider.loadReviewCards(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: contentProvider),
        ChangeNotifierProvider.value(value: reviewProvider),
      ],
      child: const TamilSetuApp(),
    ),
  );
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

          // 2. Apply your custom Peacock-inspired light theme
          theme: PeacockTheme.lightTheme,

          // 3. Apply your custom Peacock-inspired dark theme
          darkTheme: PeacockTheme.darkTheme,

          // 4. Use the state from your ThemeProvider to decide which theme to show
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          home: const DashboardScreen(),
        );
      },
    );
  }
}
