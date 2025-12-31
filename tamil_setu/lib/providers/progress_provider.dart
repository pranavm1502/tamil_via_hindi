import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkpoint.dart';

class ProgressProvider with ChangeNotifier {
  // --- State Variables ---

  // Tracks how many levels are unlocked (starts at 1, so Level 1 is open)
  int _unlockedLevel = 1;

  // Tracks exactly which lessons (by index) are completed
  final Set<int> _completedLessons = {};

  // Tracks completed checkpoint numbers (0, 1, 2...)
  final Set<int> _completedCheckpoints = {};

  // Optionally track specific scores (useful for "Best Score" displays)
  final Map<int, int> _lessonScores = {};

  // --- Getters ---
  int get unlockedLevel => _unlockedLevel;
  int get totalCompletedLessons => _completedLessons.length;
  Set<int> get completedCheckpoints => Set.from(_completedCheckpoints);

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

    // Load the list of completed checkpoint indices
    final completedCheckpointsList = prefs.getStringList('completedCheckpoints');
    if (completedCheckpointsList != null) {
      _completedCheckpoints.clear();
      _completedCheckpoints.addAll(completedCheckpointsList.map((e) => int.parse(e)));
    }

    notifyListeners();
  }

  // --- Core Logic ---

  /// Checks if a specific lesson index should be locked.
  /// Logic: Lessons are locked if:
  /// 1. They are beyond the unlocked level, OR
  /// 2. They require a checkpoint that hasn't been completed
  bool isLessonLocked(int lessonIndex) {
    // Basic level check
    if (lessonIndex >= _unlockedLevel) {
      return true;
    }

    // Check if this lesson requires a checkpoint to be completed
    final requiredCheckpoint = (lessonIndex) ~/ CheckpointService.lessonsPerSection - 1;
    if (requiredCheckpoint >= 0 && !_completedCheckpoints.contains(requiredCheckpoint)) {
      return true;
    }

    return false;
  }

  /// Checks if a checkpoint is locked (requires previous lessons to be completed)
  bool isCheckpointLocked(int checkpointNumber) {
    // Checkpoint N requires lessons ((N-1)*5) through ((N-1)*5+4) to be completed
    // Since checkpoints are numbered starting from 1, we need to subtract 1
    final startLesson = (checkpointNumber - 1) * CheckpointService.lessonsPerSection;
    final endLesson = startLesson + CheckpointService.lessonsPerSection - 1;

    // Check if all lessons in this section are completed
    for (int i = startLesson; i <= endLesson; i++) {
      if (!_completedLessons.contains(i)) {
        return true; // Still locked
      }
    }

    return false; // All lessons completed, checkpoint unlocked
  }

  /// Checks if a checkpoint has been completed
  bool isCheckpointCompleted(int checkpointNumber) {
    return _completedCheckpoints.contains(checkpointNumber);
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

  /// Save checkpoint quiz score and unlock next section if passed
  Future<void> saveCheckpointScore(int checkpointNumber, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final double percentage = (score / total) * 100;

    // Checkpoint requires 80% to pass
    if (percentage >= 80) {
      if (!_completedCheckpoints.contains(checkpointNumber)) {
        _completedCheckpoints.add(checkpointNumber);
        await prefs.setStringList('completedCheckpoints',
            _completedCheckpoints.map((e) => e.toString()).toList());
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
    _completedCheckpoints.clear();
    _lessonScores.clear();
    notifyListeners();
  }
}

