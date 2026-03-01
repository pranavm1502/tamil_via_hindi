import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/screens/dashboard_screen.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_mock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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
            ChangeNotifierProvider(create: (_) => MistakeProvider()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Daily Goal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Daily Goal'), findsOneWidget);
  });
}
