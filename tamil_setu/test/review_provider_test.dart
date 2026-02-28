import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/models/review_card.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/services/review_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quick Review falls back when none due', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = ReviewStorageService();

    final futureCard = ReviewCard(
      id: 'lesson0_word0',
      lessonIndex: 0,
      wordIndex: 0,
      nextReview: DateTime.now().add(const Duration(days: 3)),
      repetitions: 2,
      easiness: 2.5,
      intervalDays: 3,
      createdAt: DateTime.now(),
    );
    await storage.saveReviewCards([futureCard]);

    final provider = ReviewProvider();
    await provider.loadReviewCards();
    provider.startReviewSession();

    expect(provider.totalCardsInSession, 1);
  });

  test('Daily goal updates persist', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ReviewProvider();
    await provider.loadReviewCards();

    await provider.setDailyGoalCards(20);
    expect(provider.dailyGoalCards, 20);
  });
}
