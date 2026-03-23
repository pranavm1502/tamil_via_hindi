import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/models/review_card.dart';
import 'package:tamil_setu/providers/review_provider.dart';
import 'package:tamil_setu/services/review_storage_service.dart';
import 'package:tamil_setu/services/srs_service.dart';

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

  group('Session mistakes tracking', () {
    late ReviewStorageService storage;
    late ReviewProvider provider;

    ReviewCard dueCard(String id, int lessonIndex, int wordIndex) =>
        ReviewCard(
          id: id,
          lessonIndex: lessonIndex,
          wordIndex: wordIndex,
          nextReview: DateTime.now().subtract(const Duration(hours: 1)),
          repetitions: 1,
          easiness: 2.5,
          intervalDays: 1,
          createdAt: DateTime.now(),
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = ReviewStorageService();
      provider = ReviewProvider();
    });

    test('session mistakes list is empty at session start', () async {
      final card = dueCard('lesson0_word0', 0, 0);
      await storage.saveReviewCards([card]);
      await provider.loadReviewCards();
      provider.startReviewSession();

      expect(provider.sessionMistakes, isEmpty);
    });

    test('card answered again is added to session mistakes', () async {
      final card = dueCard('lesson0_word0', 0, 0);
      await storage.saveReviewCards([card]);
      await provider.loadReviewCards();
      provider.startReviewSession();

      await provider.reviewCurrentCard(ReviewQuality.again);

      expect(provider.sessionMistakes, hasLength(1));
      expect(provider.sessionMistakes.first.id, 'lesson0_word0');
    });

    test('card answered good is NOT added to session mistakes', () async {
      final card = dueCard('lesson0_word0', 0, 0);
      await storage.saveReviewCards([card]);
      await provider.loadReviewCards();
      provider.startReviewSession();

      await provider.reviewCurrentCard(ReviewQuality.good);

      expect(provider.sessionMistakes, isEmpty);
    });

    test('session mistakes are cleared when a new session starts', () async {
      final cards = [
        dueCard('lesson0_word0', 0, 0),
        dueCard('lesson0_word1', 0, 1),
      ];
      await storage.saveReviewCards(cards);
      await provider.loadReviewCards();

      // First session — answer both wrong
      provider.startReviewSession();
      await provider.reviewCurrentCard(ReviewQuality.again);
      await provider.reviewCurrentCard(ReviewQuality.again);
      expect(provider.sessionMistakes, hasLength(2));

      // Start a new session — mistakes should reset
      provider.startReviewSession();
      expect(provider.sessionMistakes, isEmpty);
    });

    test('only "again" answers accumulate, not hard/good/easy', () async {
      final cards = [
        dueCard('lesson0_word0', 0, 0),
        dueCard('lesson0_word1', 0, 1),
        dueCard('lesson0_word2', 0, 2),
        dueCard('lesson0_word3', 0, 3),
      ];
      await storage.saveReviewCards(cards);
      await provider.loadReviewCards();
      provider.startReviewSession();

      await provider.reviewCurrentCard(ReviewQuality.again);
      await provider.reviewCurrentCard(ReviewQuality.hard);
      await provider.reviewCurrentCard(ReviewQuality.good);
      await provider.reviewCurrentCard(ReviewQuality.easy);

      expect(provider.sessionMistakes, hasLength(1));
    });
  });
}
