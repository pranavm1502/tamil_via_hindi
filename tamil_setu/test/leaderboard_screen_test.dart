import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/screens/leaderboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Shows empty leaderboard state', (tester) async {
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(firestore: firestore),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No leaderboard data.'), findsOneWidget);
  });

  testWidgets('Shows ranked users', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('u1').set({
      'display_name': 'Learner One',
      'total_xp': 150,
      'xp_weekly': 40,
      'streak_count': 3,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(firestore: firestore),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();
    expect(find.text('Top Learners'), findsOneWidget);
    expect(find.text('Learner One'), findsOneWidget);
    expect(find.text('XP: 150  |  Streak: 3'), findsOneWidget);
  });
}
