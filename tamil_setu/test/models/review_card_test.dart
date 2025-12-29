import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/review_card.dart';

void main() {
  group('ReviewCard', () {
    test('newCard creates card with correct defaults', () {
      final card = ReviewCard.newCard(lessonIndex: 5, wordIndex: 3);

      expect(card.lessonIndex, 5);
      expect(card.wordIndex, 3);
      expect(card.id, 'lesson5_word3');
      expect(card.repetitions, 0);
      expect(card.easiness, 2.5);
      expect(card.intervalDays, 1);
      expect(card.totalReviews, 0);
      expect(card.totalCorrect, 0);
      expect(card.lastReviewed, isNull);
      expect(card.isDue, isTrue); // New cards are immediately due
    });

    test('isDue returns true when nextReview is in the past', () {
      final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
        nextReview: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(card.isDue, isTrue);
    });

    test('isDue returns false when nextReview is in the future', () {
      final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
        nextReview: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(card.isDue, isFalse);
    });

    test('accuracy calculates correctly', () {
      final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0).copyWith(
        totalReviews: 10,
        totalCorrect: 8,
      );

      expect(card.accuracy, 80.0);
    });

    test('accuracy returns 0 for new cards', () {
      final card = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0);

      expect(card.accuracy, 0.0);
    });

    test('toJson serializes correctly', () {
      final now = DateTime.now();
      final card = ReviewCard(
        id: 'lesson0_word1',
        lessonIndex: 0,
        wordIndex: 1,
        nextReview: now.add(const Duration(days: 1)),
        repetitions: 3,
        easiness: 2.3,
        intervalDays: 7,
        lastReviewed: now,
        totalReviews: 5,
        totalCorrect: 4,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      final json = card.toJson();

      expect(json['id'], 'lesson0_word1');
      expect(json['lessonIndex'], 0);
      expect(json['wordIndex'], 1);
      expect(json['repetitions'], 3);
      expect(json['easiness'], 2.3);
      expect(json['intervalDays'], 7);
      expect(json['totalReviews'], 5);
      expect(json['totalCorrect'], 4);
      expect(json['nextReview'], isA<String>());
      expect(json['lastReviewed'], isA<String>());
      expect(json['createdAt'], isA<String>());
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'lesson2_word5',
        'lessonIndex': 2,
        'wordIndex': 5,
        'nextReview': '2025-01-15T10:00:00.000',
        'repetitions': 4,
        'easiness': 2.7,
        'intervalDays': 15,
        'lastReviewed': '2025-01-01T10:00:00.000',
        'totalReviews': 6,
        'totalCorrect': 5,
        'createdAt': '2024-12-01T10:00:00.000',
      };

      final card = ReviewCard.fromJson(json);

      expect(card.id, 'lesson2_word5');
      expect(card.lessonIndex, 2);
      expect(card.wordIndex, 5);
      expect(card.repetitions, 4);
      expect(card.easiness, 2.7);
      expect(card.intervalDays, 15);
      expect(card.totalReviews, 6);
      expect(card.totalCorrect, 5);
      expect(card.nextReview.year, 2025);
      expect(card.lastReviewed, isNotNull);
      expect(card.createdAt.year, 2024);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'lesson0_word0',
        'lessonIndex': 0,
        'wordIndex': 0,
        'nextReview': '2025-01-15T10:00:00.000',
        'createdAt': '2024-12-01T10:00:00.000',
      };

      final card = ReviewCard.fromJson(json);

      expect(card.repetitions, 0);
      expect(card.easiness, 2.5);
      expect(card.intervalDays, 1);
      expect(card.totalReviews, 0);
      expect(card.totalCorrect, 0);
      expect(card.lastReviewed, isNull);
    });

    test('copyWith creates correct copy', () {
      final original = ReviewCard.newCard(lessonIndex: 0, wordIndex: 0);

      final copy = original.copyWith(
        repetitions: 5,
        easiness: 3.0,
      );

      expect(copy.repetitions, 5);
      expect(copy.easiness, 3.0);
      // Other fields should remain unchanged
      expect(copy.lessonIndex, original.lessonIndex);
      expect(copy.wordIndex, original.wordIndex);
      expect(copy.id, original.id);
    });

    test('toString provides useful debug info', () {
      final card = ReviewCard.newCard(lessonIndex: 1, wordIndex: 2).copyWith(
        nextReview: DateTime(2025, 1, 15),
        repetitions: 3,
        easiness: 2.6,
      );

      final str = card.toString();

      expect(str, contains('lesson1_word2'));
      expect(str, contains('reps: 3'));
      expect(str, contains('ease: 2.60'));
    });

    test('round-trip serialization preserves data', () {
      final original = ReviewCard.newCard(lessonIndex: 3, wordIndex: 7).copyWith(
        repetitions: 2,
        easiness: 2.4,
        intervalDays: 6,
        totalReviews: 3,
        totalCorrect: 2,
      );

      final json = original.toJson();
      final deserialized = ReviewCard.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.lessonIndex, original.lessonIndex);
      expect(deserialized.wordIndex, original.wordIndex);
      expect(deserialized.repetitions, original.repetitions);
      expect(deserialized.easiness, original.easiness);
      expect(deserialized.intervalDays, original.intervalDays);
      expect(deserialized.totalReviews, original.totalReviews);
      expect(deserialized.totalCorrect, original.totalCorrect);
    });
  });
}
