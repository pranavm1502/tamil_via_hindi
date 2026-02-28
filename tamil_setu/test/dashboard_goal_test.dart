import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/screens/dashboard_screen.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_mock.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Daily goal card shows progress', (tester) async {
    final content = ContentProvider()..setLessonsForTesting([]);
    final review = ReviewProvider();
    final auth = AuthService(auth: MockFirebaseAuth());

    await tester.pumpWidget(
      StreamProvider<User?>.value(
        value: auth.userStream,
        initialData: null,
        child: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            ChangeNotifierProvider.value(value: content),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider.value(value: review),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Daily Goal'), findsOneWidget);
  });
}
