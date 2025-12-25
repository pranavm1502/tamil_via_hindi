import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> waitForLoader(WidgetTester tester) async {
  // 1. Pump once to start the animation
  await tester.pump();

  // 2. Loop for up to 5 seconds waiting for the spinner to vanish
  bool loaderExists = true;
  for (int i = 0; i < 50; i++) {
    // 50 * 100ms = 5 seconds
    // Check if the spinner is still on screen
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      loaderExists = false;
      break;
    }
    // Advance time by 100ms to let the spinner spin and Future complete
    await tester.pump(const Duration(milliseconds: 100));
  }

  // 3. If it's still there after 5 seconds, throw a clear error
  if (loaderExists) {
    throw Exception(
        '🚨 TEST FAILED: The Loading Spinner never disappeared. Check your JSON loader or Provider logic.');
  }

  // 4. Once the spinner is gone, we can safely settle (for navigation animations etc)
  await tester.pumpAndSettle();
}
