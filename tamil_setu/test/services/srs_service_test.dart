import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/review_card.dart';
import 'package:tamil_setu/services/srs_service.dart';

void main() {
  group('SRSService', () {
    late SRSService srsService;

    setUp(() {
      srsService = SRSService();
    });

    group('updateCard', () {
      test('updates card with "again" quality - resets progress', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 3,
          easiness: 2.5,
          intervalDays: 10,
        );

        final updated = srsService.updateCard(card, ReviewQuality.again);

        expect(updated.repetitions, 0);
        expect(updated.intervalDays, 1);
        expect(updated.totalReviews, 1);
        expect(updated.totalCorrect, 0);
        // Should be scheduled for review in 10 minutes
        expect(
          updated.nextReview.difference(DateTime.now()).inMinutes,
          closeTo(10, 1),
        );
      });

      test('updates card with "hard" quality - increases interval less', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 2,
          easiness: 2.5,
          intervalDays: 6,
        );

        final updated = srsService.updateCard(card, ReviewQuality.hard);

        expect(updated.repetitions, 3);
        expect(updated.totalReviews, 1);
        expect(updated.totalCorrect, 1);
        // Hard should reduce interval by 20%
        expect(updated.intervalDays, lessThan(15)); // 6 * 2.5 * 0.8 = 12
      });

      test('updates card with "good" quality - normal interval increase', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 2,
          easiness: 2.5,
          intervalDays: 6,
        );

        final updated = srsService.updateCard(card, ReviewQuality.good);

        expect(updated.repetitions, 3);
        expect(updated.totalReviews, 1);
        expect(updated.totalCorrect, 1);
        // Good uses standard SM-2: 6 * 2.5 = 15
        expect(updated.intervalDays, 15);
      });

      test('updates card with "easy" quality - increases interval more', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 2,
          easiness: 2.5,
          intervalDays: 6,
        );

        final updated = srsService.updateCard(card, ReviewQuality.easy);

        expect(updated.repetitions, 3);
        expect(updated.totalReviews, 1);
        expect(updated.totalCorrect, 1);
        // Easy increases interval by 30%: 6 * 2.5 * 1.3 = 19.5 -> 20
        expect(updated.intervalDays, greaterThanOrEqualTo(19));
      });

      test('first review with good quality sets 1 day interval', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0);

        final updated = srsService.updateCard(card, ReviewQuality.good);

        expect(updated.repetitions, 1);
        expect(updated.intervalDays, 1);
      });

      test('second review with good quality sets 6 day interval', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 1,
          intervalDays: 1,
        );

        final updated = srsService.updateCard(card, ReviewQuality.good);

        expect(updated.repetitions, 2);
        expect(updated.intervalDays, 6);
      });

      test('easiness factor decreases with low quality', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          easiness: 2.5,
        );

        final updated = srsService.updateCard(card, ReviewQuality.hard);

        // Easiness should decrease
        expect(updated.easiness, lessThan(2.5));
      });

      test('easiness factor increases with high quality', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          easiness: 2.0,
        );

        final updated = srsService.updateCard(card, ReviewQuality.easy);

        // Easiness should increase
        expect(updated.easiness, greaterThan(2.0));
      });

      test('easiness factor never drops below 1.3', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          easiness: 1.35,
        );

        final updated = srsService.updateCard(card, ReviewQuality.hard);

        expect(updated.easiness, greaterThanOrEqualTo(1.3));
      });
    });

    group('getDueCards', () {
      test('returns only cards that are due', () {
        final now = DateTime.now();
        final cards = [
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
            nextReview: now.subtract(const Duration(days: 1)), // Overdue
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 1).copyWith(
            nextReview: now, // Due now
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 2).copyWith(
            nextReview: now.add(const Duration(days: 1)), // Not due
          ),
        ];

        final dueCards = srsService.getDueCards(cards);

        expect(dueCards.length, 2);
        expect(dueCards[0].wordIndex, 0);
        expect(dueCards[1].wordIndex, 1);
      });
    });

    group('getStatistics', () {
      test('calculates correct statistics', () {
        final cards = [
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
            repetitions: 0,
            totalReviews: 0,
            totalCorrect: 0,
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 1).copyWith(
            repetitions: 2,
            totalReviews: 3,
            totalCorrect: 2,
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 2).copyWith(
            repetitions: 5,
            totalReviews: 8,
            totalCorrect: 7,
          ),
        ];

        final stats = srsService.getStatistics(cards);

        expect(stats['totalCards'], 3);
        expect(stats['newCards'], 1); // rep = 0
        expect(stats['learningCards'], 1); // rep = 2
        expect(stats['matureCards'], 1); // rep >= 3
        expect(stats['totalReviews'], 11);
        expect(stats['totalCorrect'], 9);
        expect(stats['accuracy'], closeTo(81.8, 0.1));
      });
    });

    group('sortCardsForReview', () {
      test('sorts overdue cards first, then by difficulty', () {
        final now = DateTime.now();
        final cards = [
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
            nextReview: now.add(const Duration(days: 1)),
            easiness: 2.5, // Easy, not due
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 1).copyWith(
            nextReview: now.subtract(const Duration(days: 2)),
            easiness: 2.0, // Overdue, harder
          ),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 2).copyWith(
            nextReview: now.subtract(const Duration(days: 1)),
            easiness: 2.5, // Overdue, easier
          ),
        ];

        final sorted = srsService.sortCardsForReview(cards);

        // Should be sorted: overdue harder, overdue easier, not due
        expect(sorted[0].wordIndex, 1); // Overdue (2 days ago)
        expect(sorted[1].wordIndex, 2); // Overdue (1 day ago)
        expect(sorted[2].wordIndex, 0); // Not due
      });
    });

    group('groupByLesson', () {
      test('groups cards by lesson index', () {
        final cards = [
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 0),
          ReviewCard.newCard(lessonIndex: 0, wordIndex: 1),
          ReviewCard.newCard(lessonIndex: 1, wordIndex: 0),
          ReviewCard.newCard(lessonIndex: 2, wordIndex: 0),
        ];

        final grouped = srsService.groupByLesson(cards);

        expect(grouped.keys.length, 3);
        expect(grouped[0]!.length, 2);
        expect(grouped[1]!.length, 1);
        expect(grouped[2]!.length, 1);
      });
    });

    group('predictNextReview', () {
      test('predicts next review date correctly', () {
        final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
          repetitions: 2,
          intervalDays: 6,
        );

        final predicted = srsService.predictNextReview(card, ReviewQuality.good);
        final now = DateTime.now();

        // Should be approximately 15 days from now (6 * 2.5)
        expect(
          predicted.difference(now).inDays,
          closeTo(15, 1),
        );
      });
    });
  });
}
