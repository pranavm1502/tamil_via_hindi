import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/content_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme.dart'; // 1. Import your newly created theme file

void main() async {
  // Ensure Flutter bindings are initialized for async data loading
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize providers
  final progressProvider = ProgressProvider();
  final themeProvider = ThemeProvider();
  final contentProvider = ContentProvider();

  // Load persistent data (Progress, Themes, and Lesson Content) before the app starts
  await Future.wait([
    progressProvider.loadProgress(),
    themeProvider.initialize(),
    contentProvider.loadContent(), 
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: contentProvider),
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
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          home: const DashboardScreen(),
        );
      },
    );
  }
}