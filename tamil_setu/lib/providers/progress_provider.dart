import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider with ChangeNotifier {
  int _unlockedLevel = 1;
  final Map<int, bool> _completedLessons = {};

  int get unlockedLevel => _unlockedLevel;
  int get totalCompletedLessons => _completedLessons.length;

  // Loads progress from the phone's storage on startup
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    notifyListeners();
  }

  bool isLevelLocked(int levelId) => levelId > _unlockedLevel;

  // 80% score unlocks the next level
  Future<void> saveQuizScore(int lessonId, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    if (score / total >= 0.8) {
      _completedLessons[lessonId] = true;
      if (lessonId == _unlockedLevel) {
        _unlockedLevel++;
        await prefs.setInt('unlockedLevel', _unlockedLevel);
      }
    }
    notifyListeners();
  }
}

// import 'package:flutter/foundation.dart';
// import '../services/progress_service.dart';

// /// Provider for managing progress state throughout the app.
// class ProgressProvider with ChangeNotifier {
//   final ProgressService _progressService = ProgressService();

//   List<int> _completedLessons = [];
//   Map<int, int> _lessonScores = {};

//   List<int> get completedLessons => _completedLessons;

//   /// Initialize the provider by loading saved progress.
//   Future<void> initialize() async {
//     await loadProgress();
//   }

//   /// Load all progress data from storage.
//   Future<void> loadProgress() async {
//     _completedLessons = await _progressService.getCompletedLessons();
//     notifyListeners();
//   }

//   /// Check if a lesson is completed.
//   bool isLessonCompleted(int lessonIndex) {
//     return _completedLessons.contains(lessonIndex);
//   }

//   /// Mark a lesson as completed.
//   Future<void> markLessonCompleted(int lessonIndex) async {
//     await _progressService.markLessonCompleted(lessonIndex);
//     await loadProgress();
//   }

//   /// Save quiz score and update progress.
//   Future<void> saveQuizScore(int lessonIndex, int score, int total) async {
//     await _progressService.saveQuizScore(lessonIndex, score, total);
//     _lessonScores[lessonIndex] = (score / total * 100).round();
//     await loadProgress();
//   }

//   /// Get best score percentage for a lesson.
//   Future<int?> getBestScore(int lessonIndex) async {
//     if (_lessonScores.containsKey(lessonIndex)) {
//       return _lessonScores[lessonIndex];
//     }

//     final percentage =
//         await _progressService.getBestScorePercentage(lessonIndex);
//     if (percentage != null) {
//       _lessonScores[lessonIndex] = percentage;
//     }
//     return percentage;
//   }

//   /// Get total number of completed lessons.
//   int get totalCompletedLessons => _completedLessons.length;

//   /// Get overall progress percentage for given total lessons.
//   int getOverallProgress(int totalLessons) {
//     if (totalLessons == 0) return 0;
//     return (totalCompletedLessons / totalLessons * 100).round();
//   }

//   /// Clear all progress.
//   Future<void> clearAllProgress() async {
//     await _progressService.clearAllProgress();
//     _completedLessons = [];
//     _lessonScores = {};
//     notifyListeners();
//   }
// }
