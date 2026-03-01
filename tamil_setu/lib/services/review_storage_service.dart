import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_card.dart';

/// Service for persisting review cards to local storage.
class ReviewStorageService {
  static const String _reviewCardsKey = 'review_cards';
  static const String _reviewStatsKey = 'review_stats';

  /// Load all review cards from storage
  Future<List<ReviewCard>> loadReviewCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString(_reviewCardsKey);

      if (cardsJson == null || cardsJson.isEmpty) {
        return [];
      }

      final List<dynamic> cardsList = json.decode(cardsJson);
      return cardsList.map((json) => ReviewCard.fromJson(json)).toList();
    } catch (e) {
      // If there's any error loading cards, return empty list
      // In production, you might want to log this error
      return [];
    }
  }

  /// Save all review cards to storage
  Future<void> saveReviewCards(List<ReviewCard> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(cards.map((c) => c.toJson()).toList());
      await prefs.setString(_reviewCardsKey, cardsJson);
    } catch (e) {
      // Handle error - in production, you might want to throw or log
      rethrow;
    }
  }

  /// Add or update a single review card
  Future<void> upsertReviewCard(ReviewCard card) async {
    final cards = await loadReviewCards();
    final existingIndex = cards.indexWhere((c) => c.id == card.id);

    if (existingIndex != -1) {
      cards[existingIndex] = card;
    } else {
      cards.add(card);
    }

    await saveReviewCards(cards);
  }

  /// Batch upsert multiple cards (more efficient than individual upserts)
  Future<void> upsertReviewCards(List<ReviewCard> newCards) async {
    final existingCards = await loadReviewCards();
    final Map<String, ReviewCard> cardMap = {
      for (var card in existingCards) card.id: card
    };

    // Update or add new cards
    for (var card in newCards) {
      cardMap[card.id] = card;
    }

    await saveReviewCards(cardMap.values.toList());
  }

  /// Delete a review card
  Future<void> deleteReviewCard(String cardId) async {
    final cards = await loadReviewCards();
    cards.removeWhere((c) => c.id == cardId);
    await saveReviewCards(cards);
  }

  /// Delete all review cards for a specific lesson
  Future<void> deleteCardsForLesson(int lessonIndex) async {
    final cards = await loadReviewCards();
    cards.removeWhere((c) => c.lessonIndex == lessonIndex);
    await saveReviewCards(cards);
  }

  /// Get review cards for a specific lesson
  Future<List<ReviewCard>> getCardsForLesson(int lessonIndex) async {
    final cards = await loadReviewCards();
    return cards.where((c) => c.lessonIndex == lessonIndex).toList();
  }

  /// Check if a review card exists for a word
  Future<bool> cardExists(int lessonIndex, int wordIndex) async {
    final cards = await loadReviewCards();
    final cardId = 'lesson${lessonIndex}_word$wordIndex';
    return cards.any((c) => c.id == cardId);
  }

  /// Clear all review cards (for testing or reset)
  Future<void> clearAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reviewCardsKey);
    await prefs.remove(_reviewStatsKey);
  }

  /// Save global review statistics
  Future<void> saveReviewStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reviewStatsKey, json.encode(stats));
  }

  /// Load global review statistics
  Future<Map<String, dynamic>> loadReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_reviewStatsKey);

      if (statsJson == null || statsJson.isEmpty) {
        return {
          'totalReviewSessions': 0,
          'totalCardsReviewed': 0,
          'totalTimeSpentMinutes': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'lastReviewDate': null,
          'cardsReviewedToday': 0,
          'dailyGoalCards': 10,
          'reminderTime': null,
          'streakFreezes': 2,
          'lastFreezeDate': null,
          'lastFreezeAwardStreak': 0,
          'lastLessonFreezeDate': null,
        };
      }

      return json.decode(statsJson);
    } catch (e) {
      // Return default stats on error
      return {
        'totalReviewSessions': 0,
        'totalCardsReviewed': 0,
        'totalTimeSpentMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastReviewDate': null,
        'cardsReviewedToday': 0,
        'dailyGoalCards': 10,
        'reminderTime': null,
        'streakFreezes': 2,
        'lastFreezeDate': null,
        'lastFreezeAwardStreak': 0,
        'lastLessonFreezeDate': null,
      };
    }
  }

  /// Update streak based on review activity
  Future<void> updateStreak() async {
    final stats = await loadReviewStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastReviewStr = stats['lastReviewDate'] as String?;

    if (lastReviewStr == null) {
      // First review ever
      stats['currentStreak'] = 1;
      stats['longestStreak'] = 1;
      stats['lastReviewDate'] = today.toIso8601String();
    } else {
      final lastReview = DateTime.parse(lastReviewStr);
      final lastReviewDay =
          DateTime(lastReview.year, lastReview.month, lastReview.day);

      final daysSinceLastReview = today.difference(lastReviewDay).inDays;

      if (daysSinceLastReview == 0) {
        // Already reviewed today - no change to streak
      } else if (daysSinceLastReview == 1) {
        // Consecutive day - increment streak
        stats['currentStreak'] = (stats['currentStreak'] ?? 0) + 1;
        stats['lastReviewDate'] = today.toIso8601String();

        final lastAwardStreak = (stats['lastFreezeAwardStreak'] ?? 0) as int;
        if (stats['currentStreak'] == 3 && lastAwardStreak != 3) {
          final nextFreezes = (stats['streakFreezes'] ?? 0) + 1;
          stats['streakFreezes'] = nextFreezes > 4 ? 4 : nextFreezes;
          stats['lastFreezeAwardStreak'] = 3;
        }

        // Update longest streak if needed
        if (stats['currentStreak'] > (stats['longestStreak'] ?? 0)) {
          stats['longestStreak'] = stats['currentStreak'];
        }
      } else {
        final freezes = (stats['streakFreezes'] ?? 0) as int;
        final lastFreezeStr = stats['lastFreezeDate'] as String?;
        final lastFreezeDay = lastFreezeStr == null
            ? null
            : DateTime.parse(lastFreezeStr);
        final usedFreezeToday = lastFreezeDay != null &&
            lastFreezeDay.year == today.year &&
            lastFreezeDay.month == today.month &&
            lastFreezeDay.day == today.day;

        if (freezes > 0 && !usedFreezeToday) {
          // Consume a freeze to preserve the current streak.
          stats['streakFreezes'] = freezes - 1;
          stats['lastFreezeDate'] = today.toIso8601String();
          stats['lastReviewDate'] = today.toIso8601String();
        } else {
          // Streak broken - reset to 1
          stats['currentStreak'] = 1;
          stats['lastReviewDate'] = today.toIso8601String();
          stats['lastFreezeAwardStreak'] = 0;
        }
      }
    }

    await saveReviewStats(stats);
  }

  /// Increment total review session count
  Future<void> incrementReviewSession(
      int cardsReviewed, int minutesSpent) async {
    final stats = await loadReviewStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReviewStr = stats['lastReviewDate'] as String?;
    if (lastReviewStr == null) {
      stats['lastReviewDate'] = today.toIso8601String();
      stats['cardsReviewedToday'] = 0;
    } else {
      final lastReview = DateTime.parse(lastReviewStr);
      final lastReviewDay =
          DateTime(lastReview.year, lastReview.month, lastReview.day);
      if (lastReviewDay != today) {
        stats['cardsReviewedToday'] = 0;
        stats['lastReviewDate'] = today.toIso8601String();
      }
    }

    stats['totalReviewSessions'] = (stats['totalReviewSessions'] ?? 0) + 1;
    stats['totalCardsReviewed'] =
        (stats['totalCardsReviewed'] ?? 0) + cardsReviewed;
    stats['totalTimeSpentMinutes'] =
        (stats['totalTimeSpentMinutes'] ?? 0) + minutesSpent;
    stats['cardsReviewedToday'] =
        (stats['cardsReviewedToday'] ?? 0) + cardsReviewed;
    await saveReviewStats(stats);
  }

  /// Increment daily goal progress without creating a review session.
  Future<void> incrementCardsReviewedToday(int cardsReviewed) async {
    final stats = await loadReviewStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReviewStr = stats['lastReviewDate'] as String?;

    if (lastReviewStr == null) {
      stats['lastReviewDate'] = today.toIso8601String();
      stats['cardsReviewedToday'] = 0;
    } else {
      final lastReview = DateTime.parse(lastReviewStr);
      final lastReviewDay =
          DateTime(lastReview.year, lastReview.month, lastReview.day);
      if (lastReviewDay != today) {
        stats['cardsReviewedToday'] = 0;
        stats['lastReviewDate'] = today.toIso8601String();
      }
    }

    stats['totalCardsReviewed'] =
        (stats['totalCardsReviewed'] ?? 0) + cardsReviewed;
    stats['cardsReviewedToday'] =
        (stats['cardsReviewedToday'] ?? 0) + cardsReviewed;
    await saveReviewStats(stats);
  }

  /// Award a freeze for completing a lesson once per week.
  Future<bool> awardWeeklyLessonFreeze() async {
    final stats = await loadReviewStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLessonFreezeStr = stats['lastLessonFreezeDate'] as String?;
    final lastLessonFreezeDay = lastLessonFreezeStr == null
        ? null
        : DateTime.parse(lastLessonFreezeStr);

    final daysSinceLast = lastLessonFreezeDay == null
        ? 999
        : today.difference(lastLessonFreezeDay).inDays;

    if (daysSinceLast < 7) {
      return false;
    }

    final nextFreezes = (stats['streakFreezes'] ?? 0) + 1;
    stats['streakFreezes'] = nextFreezes > 4 ? 4 : nextFreezes;
    stats['lastLessonFreezeDate'] = today.toIso8601String();
    await saveReviewStats(stats);
    return true;
  }
}
