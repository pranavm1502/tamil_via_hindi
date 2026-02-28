import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamil_setu/screens/profile_screen.dart';
import 'package:tamil_setu/providers/progress_provider.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/services/auth_service.dart';
import 'package:tamil_setu/services/review_storage_service.dart';
import 'package:tamil_setu/services/sync_service.dart';
import 'firebase_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profile shows stats when signed in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ReviewStorageService().saveReviewStats({
      'totalReviews': 12,
      'newCards': 4,
      'matureCards': 2,
      'accuracy': 75.0,
      'dailyGoalCards': 10,
      'cardsReviewedToday': 3,
      'reminderTime': null,
      'totalReviewSessions': 1,
      'totalCardsReviewed': 12,
      'totalTimeSpentMinutes': 6,
      'currentStreak': 1,
      'longestStreak': 1,
      'lastReviewDate': null,
    });

    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('test_uid').set({
      'display_name': 'Learner',
      'total_xp': 200,
      'streak_count': 4,
    });
    final sync = SyncService(db: firestore);

    final progress = ProgressProvider();
    final review = ReviewProvider();
    await review.loadReviewCards();

    final user = MockUser();
    final auth = AuthService(auth: MockFirebaseAuth(user));

    await tester.pumpWidget(
      StreamProvider<User?>.value(
        value: Stream.value(user),
        initialData: user,
        child: MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider.value(value: review),
          ],
          child: MaterialApp(
            home: ProfileScreen(syncService: sync),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Learning Stats'), findsOneWidget);
    expect(find.text('Total XP'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
  });
}
