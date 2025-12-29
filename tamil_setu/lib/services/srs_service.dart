import '../models/review_card.dart';

/// Quality rating for SM-2 algorithm
enum ReviewQuality {
  again(0),  // Complete blackout, didn't remember
  hard(3),   // Correct response, but with serious difficulty
  good(4),   // Correct response after hesitation
  easy(5);   // Perfect response, no hesitation

  final int value;
  const ReviewQuality(this.value);
}

/// Service implementing the SM-2 (SuperMemo 2) spaced repetition algorithm.
///
/// The SM-2 algorithm calculates optimal review intervals based on:
/// - Easiness factor (how difficult the card is for the user)
/// - Number of consecutive correct repetitions
/// - Quality of recall (again/hard/good/easy)
///
/// Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
class SRSService {
  /// Update a review card based on user's recall quality.
  ///
  /// Returns an updated ReviewCard with new scheduling parameters.
  ReviewCard updateCard(ReviewCard card, ReviewQuality quality) {
    final now = DateTime.now();

    // Update statistics
    final newTotalReviews = card.totalReviews + 1;
    final newTotalCorrect = quality != ReviewQuality.again
        ? card.totalCorrect + 1
        : card.totalCorrect;

    // Calculate new easiness factor
    // SM-2 formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    // where q is quality (0-5)
    double newEasiness = card.easiness +
        (0.1 - (5 - quality.value) * (0.08 + (5 - quality.value) * 0.02));

    // Easiness should never drop below 1.3
    if (newEasiness < 1.3) {
      newEasiness = 1.3;
    }

    int newRepetitions;
    int newInterval;
    DateTime newNextReview;

    if (quality == ReviewQuality.again) {
      // Failed recall - reset repetitions and review soon
      newRepetitions = 0;
      newInterval = 1;
      newNextReview = now.add(const Duration(minutes: 10)); // Review in 10 minutes
    } else {
      // Successful recall - calculate next interval
      newRepetitions = card.repetitions + 1;

      if (newRepetitions == 1) {
        newInterval = 1; // 1 day
      } else if (newRepetitions == 2) {
        newInterval = 6; // 6 days
      } else {
        // SM-2 formula: I(n) = I(n-1) * EF
        newInterval = (card.intervalDays * newEasiness).round();
      }

      // Apply quality modifier to interval
      switch (quality) {
        case ReviewQuality.easy:
          newInterval = (newInterval * 1.3).round(); // 30% longer
          break;
        case ReviewQuality.hard:
          newInterval = (newInterval * 0.8).round(); // 20% shorter
          break;
        default:
          break; // Good - use calculated interval as-is
      }

      // Ensure minimum interval of 1 day
      if (newInterval < 1) {
        newInterval = 1;
      }

      newNextReview = now.add(Duration(days: newInterval));
    }

    return card.copyWith(
      nextReview: newNextReview,
      repetitions: newRepetitions,
      easiness: newEasiness,
      intervalDays: newInterval,
      lastReviewed: now,
      totalReviews: newTotalReviews,
      totalCorrect: newTotalCorrect,
    );
  }

  /// Get all cards that are due for review
  List<ReviewCard> getDueCards(List<ReviewCard> allCards) {
    final now = DateTime.now();
    return allCards.where((card) => card.isDue).toList();
  }

  /// Get cards due today (not overdue from previous days)
  List<ReviewCard> getCardsToday(List<ReviewCard> allCards) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return allCards.where((card) {
      return card.nextReview.isAfter(todayStart.subtract(const Duration(days: 1))) &&
             card.nextReview.isBefore(tomorrowStart);
    }).toList();
  }

  /// Get statistics for all cards
  Map<String, dynamic> getStatistics(List<ReviewCard> allCards) {
    final dueCards = getDueCards(allCards);
    final totalReviews = allCards.fold<int>(0, (sum, card) => sum + card.totalReviews);
    final totalCorrect = allCards.fold<int>(0, (sum, card) => sum + card.totalCorrect);

    // Calculate average easiness
    final avgEasiness = allCards.isEmpty
        ? 0.0
        : allCards.fold<double>(0, (sum, card) => sum + card.easiness) / allCards.length;

    // Find cards by maturity level
    final newCards = allCards.where((c) => c.repetitions == 0).length;
    final learningCards = allCards.where((c) => c.repetitions > 0 && c.repetitions < 3).length;
    final matureCards = allCards.where((c) => c.repetitions >= 3).length;

    return {
      'totalCards': allCards.length,
      'dueCards': dueCards.length,
      'newCards': newCards,
      'learningCards': learningCards,
      'matureCards': matureCards,
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
      'accuracy': totalReviews == 0 ? 0.0 : (totalCorrect / totalReviews) * 100,
      'avgEasiness': avgEasiness,
    };
  }

  /// Predict the next review date for a card based on quality
  DateTime predictNextReview(ReviewCard card, ReviewQuality quality) {
    final updatedCard = updateCard(card, quality);
    return updatedCard.nextReview;
  }

  /// Get cards grouped by lesson
  Map<int, List<ReviewCard>> groupByLesson(List<ReviewCard> cards) {
    final Map<int, List<ReviewCard>> grouped = {};
    for (final card in cards) {
      if (!grouped.containsKey(card.lessonIndex)) {
        grouped[card.lessonIndex] = [];
      }
      grouped[card.lessonIndex]!.add(card);
    }
    return grouped;
  }

  /// Sort cards for optimal review order (hardest first)
  List<ReviewCard> sortCardsForReview(List<ReviewCard> cards) {
    final sorted = List<ReviewCard>.from(cards);
    sorted.sort((a, b) {
      // Overdue cards first (oldest overdue first)
      if (a.isDue && b.isDue) {
        return a.nextReview.compareTo(b.nextReview);
      }
      if (a.isDue && !b.isDue) return -1;
      if (!a.isDue && b.isDue) return 1;

      // Then by difficulty (lower easiness = harder = higher priority)
      return a.easiness.compareTo(b.easiness);
    });
    return sorted;
  }
}
