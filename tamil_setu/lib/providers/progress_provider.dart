import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider with ChangeNotifier {
  // --- State Variables ---

  // Tracks how many levels are unlocked (starts at 1, so Level 1 is open)
  int _unlockedLevel = 1;

  // Tracks exactly which lessons (by index) are completed
  final Set<int> _completedLessons = {};

  // Optionally track specific scores (useful for "Best Score" displays)
  final Map<int, int> _lessonScores = {};

  // --- Getters ---
  int get unlockedLevel => _unlockedLevel;
  int get totalCompletedLessons => _completedLessons.length;

  // --- Initialization ---

  /// Loads progress from the phone's storage on startup.
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Load the unlocked level count (Default to 1)
    _unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;

    // Load the list of completed lesson indices
    final completedList = prefs.getStringList('completedLessons');
    if (completedList != null) {
      _completedLessons.clear();
      _completedLessons.addAll(completedList.map((e) => int.parse(e)));
    }

    notifyListeners();
  }

  // --- Core Logic ---

  /// Checks if a specific lesson index should be locked.
  /// Logic: If unlockedLevel is 1, index 0 is Open, index 1 is Locked.
  bool isLessonLocked(int lessonIndex) {
    // If the lesson index is greater than or equal to the number of unlocked levels, it's locked.
    return lessonIndex >= _unlockedLevel;
  }

  /// Checks if a lesson has been successfully completed previously.
  bool isLessonCompleted(int lessonIndex) {
    return _completedLessons.contains(lessonIndex);
  }

  /// Calculates the overall progress percentage for the dashboard header.
  double getOverallProgress(int totalLessons) {
    if (totalLessons == 0) return 0.0;
    return (_completedLessons.length / totalLessons) * 100;
  }

  /// Saves the quiz score and handles unlocking the next level.
  Future<void> saveQuizScore(int lessonIndex, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final double percentage = (score / total) * 100;

    // 1. Save 'Best Score' logic (Optional but good for UX)
    if (!_lessonScores.containsKey(lessonIndex) ||
        percentage > _lessonScores[lessonIndex]!) {
      _lessonScores[lessonIndex] = percentage.round();
    }

    // 2. Unlocking Logic: Requires 80% to pass
    if (percentage >= 80) {
      // Mark as completed in the set
      if (!_completedLessons.contains(lessonIndex)) {
        _completedLessons.add(lessonIndex);
        // Save list to persistent storage
        await prefs.setStringList('completedLessons',
            _completedLessons.map((e) => e.toString()).toList());
      }

      // Unlock the next level if we are at the current edge of progress
      // Example: If I finish Lesson 1 (index 0) and unlockedLevel is 1,
      // then (0 + 1) == 1. Logic holds -> Unlock Level 2.
      if ((lessonIndex + 1) == _unlockedLevel) {
        _unlockedLevel++;
        await prefs.setInt('unlockedLevel', _unlockedLevel);
      }
    }

    notifyListeners();
  }

  /// Debug utility to reset all progress.
  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _unlockedLevel = 1;
    _completedLessons.clear();
    _lessonScores.clear();
    notifyListeners();
  }
}
