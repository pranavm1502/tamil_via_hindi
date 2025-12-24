import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user progress and quiz scores.
class ProgressService {
  static const String _completedLessonsKey = 'completed_lessons';
  static const String _quizScoresKey = 'quiz_scores';

  /// Get list of completed lesson indices.
  Future<List<int>> getCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedLessonsKey) ?? [];
    return completed.map((e) => int.parse(e)).toList();
  }

  /// Mark a lesson as completed.
  Future<void> markLessonCompleted(int lessonIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedLessons();

    if (!completed.contains(lessonIndex)) {
      completed.add(lessonIndex);
      await prefs.setStringList(
        _completedLessonsKey,
        completed.map((e) => e.toString()).toList(),
      );
    }
  }

  /// Check if a lesson is completed.
  Future<bool> isLessonCompleted(int lessonIndex) async {
    final completed = await getCompletedLessons();
    return completed.contains(lessonIndex);
  }

  /// Save quiz score for a lesson.
  ///
  /// [lessonIndex] - The index of the lesson
  /// [score] - The score achieved
  /// [total] - The total possible score
  Future<void> saveQuizScore(int lessonIndex, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_quizScoresKey$lessonIndex';
    await prefs.setInt(key, score);
    await prefs.setInt('${key}_total', total);
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Mark lesson as completed if score is 80% or higher
    if (score / total >= 0.8) {
      await markLessonCompleted(lessonIndex);
    }
  }

  /// Get quiz score for a lesson.
  ///
  /// Returns a map with 'score', 'total', and 'timestamp' keys.
  /// Returns null if no score is saved.
  Future<Map<String, int>?> getQuizScore(int lessonIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_quizScoresKey$lessonIndex';
    final score = prefs.getInt(key);
    final total = prefs.getInt('${key}_total');
    final timestamp = prefs.getInt('${key}_timestamp');

    if (score == null || total == null) {
      return null;
    }

    return {
      'score': score,
      'total': total,
      'timestamp': timestamp ?? 0,
    };
  }

  /// Get the best score percentage for a lesson.
  Future<int?> getBestScorePercentage(int lessonIndex) async {
    final scoreData = await getQuizScore(lessonIndex);
    if (scoreData == null) return null;

    final score = scoreData['score']!;
    final total = scoreData['total']!;
    return (score / total * 100).round();
  }

  /// Clear all progress data.
  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get total number of completed lessons.
  Future<int> getTotalCompletedLessons() async {
    final completed = await getCompletedLessons();
    return completed.length;
  }

  /// Get overall progress percentage.
  Future<int> getOverallProgress(int totalLessons) async {
    final completed = await getTotalCompletedLessons();
    if (totalLessons == 0) return 0;
    return (completed / totalLessons * 100).round();
  }
}
