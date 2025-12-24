import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const TamilSetuApp());
}

/// Main application widget for Tamil Setu.
///
/// A Flutter application designed to help Hindi speakers learn Tamil
/// through topic-based lessons, audio support, and interactive quizzes.
class TamilSetuApp extends StatelessWidget {
  const TamilSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProgressProvider()..initialize(),
      child: MaterialApp(
        title: 'Tamil Setu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          scaffoldBackgroundColor: Colors.orange[50],
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
