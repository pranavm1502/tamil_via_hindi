import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';

Widget makeTestableWidget({required Widget child}) {
  return MultiProvider(
    providers: [
      // 1. Trigger loadProgress immediately
      ChangeNotifierProvider(
        create: (_) => ProgressProvider()..loadProgress(),
      ),

      // 2. Trigger initialize immediately
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..initialize(),
      ),

      // 3. CRITICAL FIX: Trigger loadContent immediately
      //    Without this, isLoading stays 'true' forever -> Infinite Spinner -> Timeout
      ChangeNotifierProvider(
        create: (_) => ContentProvider()..loadContent(),
      ),
    ],
    child: child,
  );
}
