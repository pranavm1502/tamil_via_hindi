import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/content_provider.dart';

Widget makeTestableWidget({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => ContentProvider()),
    ],
    child: child,
  );
}