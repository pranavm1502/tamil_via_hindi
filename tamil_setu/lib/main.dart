import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/content_provider.dart'; // 1. Add this import
import 'screens/dashboard_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize ALL providers
  final progressProvider = ProgressProvider();
  final themeProvider = ThemeProvider();
  final contentProvider = ContentProvider(); // New instance

  // 3. Load ALL persistent data before the app starts
  await Future.wait([
    progressProvider.loadProgress(),
    themeProvider.initialize(),
    contentProvider
        .loadContent(), // Load JSON here to prevent loading spinners later
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(
            value: contentProvider), // Register it here
      ],
      child: const TamilSetuApp(),
    ),
  );
}

class TamilSetuApp extends StatelessWidget {
  const TamilSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Tamil Setu',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider
              .lightTheme, // Ensure these getters exist in your ThemeProvider
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
