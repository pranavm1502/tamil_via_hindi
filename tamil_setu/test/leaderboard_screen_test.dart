import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/screens/leaderboard_screen.dart';
import 'package:tamil_setu/providers/privacy_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 20,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('Shows empty leaderboard state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = FakeFirebaseFirestore();
    final privacy = PrivacyProvider();
    await privacy.completeOnboarding(birthYear: 2000);
    await privacy.completeAdultConsent(
      trackingAllowed: true,
      socialEnabled: true,
      notificationsEnabled: true,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: privacy,
        child: MaterialApp(
          home: LeaderboardScreen(firestore: firestore),
        ),
      ),
    );

    await tester.pump();
    await pumpUntilFound(tester, find.text('No leaderboard data.'));
    expect(find.text('No leaderboard data.'), findsOneWidget);
  });

  testWidgets('Shows ranked users', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = FakeFirebaseFirestore();
    final privacy = PrivacyProvider();
    await privacy.completeOnboarding(birthYear: 2000);
    await privacy.completeAdultConsent(
      trackingAllowed: true,
      socialEnabled: true,
      notificationsEnabled: true,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: privacy,
        child: MaterialApp(
          home: LeaderboardScreen(firestore: firestore),
        ),
      ),
    );

    await firestore.collection('users').doc('u1').set({
      'display_tag': 'Neela Mor-42',
      'total_xp': 150,
      'xp_weekly': 40,
      'streak_count': 3,
    });

    await tester.pump();
    await pumpUntilFound(tester, find.text('Neela Mor-42'));
    await tester.tap(find.text('All Time'));
    await tester.pump();
    await pumpUntilFound(tester, find.textContaining('XP: 150'));
    expect(find.text('Neela Mor-42'), findsWidgets);
    expect(find.textContaining('XP: 150'), findsOneWidget);
  });
}
