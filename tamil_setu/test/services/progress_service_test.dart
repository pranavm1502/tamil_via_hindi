import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/services/progress_service.dart';

void main() {
  // Ensure the binding is initialized before using SharedPreferences mocks
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgressService progressService;

  setUp(() {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    progressService = ProgressService();
  });

  group('ProgressService', () {
    test('should return empty list for completed lessons initially', () async {
      final completed = await progressService.getCompletedLessons();
      expect(completed, isEmpty);
    });

    test('should mark a lesson as completed', () async {
      await progressService.markLessonCompleted(0);
      final completed = await progressService.getCompletedLessons();

      expect(completed, contains(0));
      expect(completed.length, 1);
    });

    test('should not duplicate completed lessons', () async {
      await progressService.markLessonCompleted(0);
      await progressService.markLessonCompleted(0);
      final completed = await progressService.getCompletedLessons();

      expect(completed.length, 1);
    });

    test('should check if a lesson is completed', () async {
      await progressService.markLessonCompleted(1);

      final isCompleted = await progressService.isLessonCompleted(1);
      final isNotCompleted = await progressService.isLessonCompleted(2);

      expect(isCompleted, isTrue);
      expect(isNotCompleted, isFalse);
    });

    test('should save quiz score', () async {
      await progressService.saveQuizScore(0, 8, 10);
      final scoreData = await progressService.getQuizScore(0);

      expect(scoreData, isNotNull);
      expect(scoreData!['score'], 8);
      expect(scoreData['total'], 10);
      expect(scoreData['timestamp'], greaterThan(0));
    });

    test('should return null for non-existent quiz score', () async {
      final scoreData = await progressService.getQuizScore(99);
      expect(scoreData, isNull);
    });

    test('should get best score percentage', () async {
      await progressService.saveQuizScore(0, 9, 10);
      final percentage = await progressService.getBestScorePercentage(0);

      expect(percentage, 90);
    });

    test('should mark lesson as completed when score is 80% or higher',
        () async {
      await progressService.saveQuizScore(0, 8, 10);
      final isCompleted = await progressService.isLessonCompleted(0);

      expect(isCompleted, isTrue);
    });

    test('should not mark lesson as completed when score is below 80%',
        () async {
      await progressService.saveQuizScore(0, 7, 10);
      final isCompleted = await progressService.isLessonCompleted(0);

      expect(isCompleted, isFalse);
    });

    test('should get total completed lessons count', () async {
      await progressService.markLessonCompleted(0);
      await progressService.markLessonCompleted(1);
      await progressService.markLessonCompleted(2);

      final total = await progressService.getTotalCompletedLessons();
      expect(total, 3);
    });

    test('should calculate overall progress percentage', () async {
      await progressService.markLessonCompleted(0);
      await progressService.markLessonCompleted(1);

      final progress = await progressService.getOverallProgress(8);
      expect(progress, 25); // 2 out of 8 = 25%
    });

    test('should return 0 progress when no lessons are completed', () async {
      final progress = await progressService.getOverallProgress(8);
      expect(progress, 0);
    });

    test('should handle zero total lessons', () async {
      final progress = await progressService.getOverallProgress(0);
      expect(progress, 0);
    });

    test('should clear all progress', () async {
      await progressService.markLessonCompleted(0);
      await progressService.saveQuizScore(0, 10, 10);

      await progressService.clearAllProgress();

      final completed = await progressService.getCompletedLessons();
      final scoreData = await progressService.getQuizScore(0);

      expect(completed, isEmpty);
      expect(scoreData, isNull);
    });
  });
}
