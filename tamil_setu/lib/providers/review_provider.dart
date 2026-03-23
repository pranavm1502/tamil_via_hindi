import 'package:flutter/material.dart';
import '../models/review_card.dart';
import '../services/srs_service.dart';
import '../services/review_storage_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';

/// Provider for managing spaced repetition review state.
class ReviewProvider with ChangeNotifier {
  final SRSService _srsService = SRSService();
  final ReviewStorageService _storageService = ReviewStorageService();

  List<ReviewCard> _allCards = [];
  List<ReviewCard> _currentReviewQueue = [];
  List<ReviewCard> _sessionMistakes = [];
  int _currentCardIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Getters
  List<ReviewCard> get allCards => _allCards;
  List<ReviewCard> get dueCards => _srsService.getDueCards(_allCards);
  int get dueCardCount => dueCards.length;
  Map<String, dynamic> get statistics => _srsService.getStatistics(_allCards);
  bool get isLoading => _isLoading;

  // Current review session getters
  List<ReviewCard> get currentReviewQueue => _currentReviewQueue;
  int get currentCardIndex => _currentCardIndex;
  int get totalCardsInSession => _currentReviewQueue.length;
  bool get hasMoreCards => _currentCardIndex < _currentReviewQueue.length;
  ReviewCard? get currentCard =>
      hasMoreCards ? _currentReviewQueue[_currentCardIndex] : null;

  /// Cards answered incorrectly (again) in the current/last review session.
  List<ReviewCard> get sessionMistakes => List.unmodifiable(_sessionMistakes);

  /// Load all review cards from storage
  Future<void> loadReviewCards() async {
    _isLoading = true;
    notifyListeners();

    _allCards = await _storageService.loadReviewCards();
    _stats = await _storageService.loadReviewStats();

    _isLoading = false;
    notifyListeners();
  }

  /// Create review cards for all words in a lesson
  Future<void> createCardsForLesson(int lessonIndex, int wordCount) async {
    final List<ReviewCard> newCards = [];

    for (int i = 0; i < wordCount; i++) {
      // Check if card already exists
      final cardExists = await _storageService.cardExists(lessonIndex, i);
      if (!cardExists) {
        newCards.add(ReviewCard.newCard(
          lessonIndex: lessonIndex,
          wordIndex: i,
        ));
      }
    }

    if (newCards.isNotEmpty) {
      await _storageService.upsertReviewCards(newCards);
      await loadReviewCards(); // Reload to update state
    }
  }

  /// Start a review session with due cards
  void startReviewSession({int? maxCards}) {
    final due = _srsService.sortCardsForReview(dueCards);
    List<ReviewCard> pool = due;

    // If nothing is due yet, surface new cards (or any cards) for practice.
    if (pool.isEmpty && _allCards.isNotEmpty) {
      final newCards = _allCards.where((c) => c.repetitions == 0).toList();
      pool = newCards.isNotEmpty
          ? newCards
          : _srsService.sortCardsForReview(_allCards);
    }

    if (maxCards != null && pool.length > maxCards) {
      _currentReviewQueue = pool.sublist(0, maxCards);
    } else {
      _currentReviewQueue = pool;
    }

    _currentCardIndex = 0;
    _sessionMistakes = [];
    notifyListeners();
  }

  /// Review the current card with a quality rating
  Future<void> reviewCurrentCard(ReviewQuality quality) async {
    if (!hasMoreCards) return;

    final currentCard = _currentReviewQueue[_currentCardIndex];
    final updatedCard = _srsService.updateCard(currentCard, quality);

    // Track session mistakes
    if (quality == ReviewQuality.again) {
      _sessionMistakes.add(currentCard);
    }

    // Update in storage
    await _storageService.upsertReviewCard(updatedCard);

    // Update in memory
    final cardIndex = _allCards.indexWhere((c) => c.id == updatedCard.id);
    if (cardIndex != -1) {
      _allCards[cardIndex] = updatedCard;
    }

    // Move to next card
    _currentCardIndex++;

    // If session complete, update stats
    if (!hasMoreCards) {
      await _finishReviewSession();
    }

    notifyListeners();
  }

  /// Finish the current review session and update statistics
  Future<void> _finishReviewSession() async {
    await _storageService.updateStreak();
    await _storageService.incrementReviewSession(
      _currentReviewQueue.length,
      (_currentReviewQueue.length * 0.5).round(), // Estimate ~30s per card
    );

    // Reload stats
    _stats = await _storageService.loadReviewStats();
  }

  /// Reset the current review session
  void resetReviewSession() {
    _currentReviewQueue = [];
    _currentCardIndex = 0;
    notifyListeners();
  }

  /// Get cards for a specific lesson
  Future<List<ReviewCard>> getCardsForLesson(int lessonIndex) async {
    return _storageService.getCardsForLesson(lessonIndex);
  }

  /// Get review statistics for dashboard display
  Map<String, dynamic> get reviewStats => _stats;

  /// Get streak information
  int get currentStreak => _stats['currentStreak'] ?? 0;
  int get longestStreak => _stats['longestStreak'] ?? 0;

  /// Daily goal settings
  int get dailyGoalCards => _stats['dailyGoalCards'] ?? 10;
  int get cardsReviewedToday {
    final base = _stats['cardsReviewedToday'] ?? 0;
    final lastReviewStr = _stats['lastReviewDate'] as String?;
    final baseToday = _isSameDay(lastReviewStr) ? base : 0;
    return hasMoreCards ? baseToday + _currentCardIndex : baseToday;
  }

  Future<void> addLessonProgress(int cardsReviewed) async {
    if (cardsReviewed <= 0) return;
    await _storageService.incrementCardsReviewedToday(cardsReviewed);
    _stats = await _storageService.loadReviewStats();
    notifyListeners();
  }

  Future<bool> awardWeeklyLessonFreeze() async {
    final awarded = await _storageService.awardWeeklyLessonFreeze();
    if (awarded) {
      _stats = await _storageService.loadReviewStats();
      notifyListeners();
    }
    return awarded;
  }
  String? get reminderTime => _stats['reminderTime'] as String?;
  TimeOfDay? get reminderTimeOfDay {
    final value = reminderTime;
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Earliest scheduled review time across all cards
  DateTime? get nextReviewAt {
    if (_allCards.isEmpty) return null;
    DateTime next = _allCards.first.nextReview;
    for (final card in _allCards) {
      if (card.nextReview.isBefore(next)) {
        next = card.nextReview;
      }
    }
    return next;
  }

  Future<void> setDailyGoalCards(int value) async {
    _stats['dailyGoalCards'] = value;
    await _storageService.saveReviewStats(_stats);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay? value) async {
    if (value == null) {
      _stats['reminderTime'] = null;
      await NotificationService().cancelDailyReminder();
    } else {
      final hours = value.hour.toString().padLeft(2, '0');
      final minutes = value.minute.toString().padLeft(2, '0');
      _stats['reminderTime'] = '$hours:$minutes';
      await NotificationService().scheduleDailyReminder(value);
      AnalyticsService().logNotificationScheduled(
        timeLocal: _stats['reminderTime'] as String,
      );
    }
    await _storageService.saveReviewStats(_stats);
    notifyListeners();
  }

  Future<void> disableReminders() async {
    _stats['reminderTime'] = null;
    await NotificationService().cancelDailyReminder();
    await _storageService.saveReviewStats(_stats);
    notifyListeners();
  }

  /// Predict when a card would be due after a given quality rating
  DateTime predictNextReview(ReviewCard card, ReviewQuality quality) {
    return _srsService.predictNextReview(card, quality);
  }

  /// Clear all review data (for testing/reset)
  Future<void> clearAllReviewData() async {
    await _storageService.clearAllCards();
    _allCards = [];
    _currentReviewQueue = [];
    _currentCardIndex = 0;
    _stats = {};
    notifyListeners();
  }

  /// Get cards grouped by lesson
  Map<int, List<ReviewCard>> get cardsByLesson {
    return _srsService.groupByLesson(_allCards);
  }

  /// Get maturity breakdown
  Map<String, int> get maturityBreakdown {
    final newCards = _allCards.where((c) => c.repetitions == 0).length;
    final learningCards =
        _allCards.where((c) => c.repetitions > 0 && c.repetitions < 3).length;
    final matureCards = _allCards.where((c) => c.repetitions >= 3).length;

    return {
      'new': newCards,
      'learning': learningCards,
      'mature': matureCards,
    };
  }

  /// Check if user has reviewed today
  bool get hasReviewedToday {
    final lastReviewStr = _stats['lastReviewDate'] as String?;
    if (lastReviewStr == null) return false;

    final lastReview = DateTime.parse(lastReviewStr);
    final today = DateTime.now();

    return lastReview.year == today.year &&
        lastReview.month == today.month &&
        lastReview.day == today.day;
  }

  bool _isSameDay(String? lastReviewStr) {
    if (lastReviewStr == null) return false;
    final lastReview = DateTime.parse(lastReviewStr);
    final today = DateTime.now();
    return lastReview.year == today.year &&
        lastReview.month == today.month &&
        lastReview.day == today.day;
  }
}
