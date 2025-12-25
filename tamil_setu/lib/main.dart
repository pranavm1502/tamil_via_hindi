import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized for SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize providers before the app starts to prevent UI flickering
  final progressProvider = ProgressProvider();
  final themeProvider = ThemeProvider();

  // Load persistent data
  await Future.wait([
    progressProvider.loadProgress(), // Using the loadProgress we discussed
    themeProvider.initialize(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const TamilSetuApp(),
    ),
  );
}

class TamilSetuApp extends StatelessWidget {
  const TamilSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Consume the ThemeProvider to reactively update the UI
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Tamil Setu',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          // 4. DashboardScreen now has access to pre-loaded progress data
          home: const DashboardScreen(),
        );
      },
    );
  }
}
