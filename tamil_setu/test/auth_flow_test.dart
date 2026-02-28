import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/screens/dashboard_screen.dart';
import 'package:tamil_setu/providers/content_provider.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/theme_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/providers/mistake_provider.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'firebase_mock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestAuthService extends AuthService {
  final StreamController<User?> controller;
  final User? user;

  TestAuthService({required this.controller, this.user});

  @override
  Stream<User?> get userStream => controller.stream;

  @override
  User? get currentUser => user;

  @override
  Future<User?> signInWithGoogle() async {
    controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    controller.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Shows sign-in card when signed out', (tester) async {
    final controller = StreamController<User?>.broadcast();
    final auth = TestAuthService(controller: controller, user: MockUser());

    final content = ContentProvider()..setLessonsForTesting([]);

    await tester.pumpWidget(
      StreamProvider<User?>.value(
        value: controller.stream,
        initialData: null,
        child: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            ChangeNotifierProvider.value(value: content),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ReviewProvider()),
            ChangeNotifierProvider(create: (_) => MistakeProvider()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Save your progress'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);

    await controller.close();
  });

  testWidgets('Shows sign-out icon when signed in', (tester) async {
    final controller = StreamController<User?>.broadcast();
    final user = MockUser();
    final auth = TestAuthService(controller: controller, user: user);

    final content = ContentProvider()..setLessonsForTesting([]);

    await tester.pumpWidget(
      StreamProvider<User?>.value(
        value: controller.stream,
        initialData: null,
        child: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            ChangeNotifierProvider.value(value: content),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ReviewProvider()),
            ChangeNotifierProvider(create: (_) => MistakeProvider()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    controller.add(user);
    await tester.pump();

    expect(find.byIcon(Icons.logout), findsOneWidget);

    await controller.close();
  });
}
