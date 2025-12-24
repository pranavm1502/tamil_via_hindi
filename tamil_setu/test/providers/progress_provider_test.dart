import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_setu/providers/progress_provider.dart';

void main() {
  late ProgressProvider progressProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    progressProvider = ProgressProvider();
  });

  group('ProgressProvider', () {
    test('should initialize with empty completed lessons', () async {
      await progressProvider.initialize();
      expect(progressProvider.completedLessons, isEmpty);
    });

    test('should load progress on initialization', () async {
      // Setup some initial data
      SharedPreferences.setMockInitialValues({
        'completed_lessons': ['0', '1'],
      });

      progressProvider = ProgressProvider();
      await progressProvider.initialize();

      expect(progressProvider.completedLessons, contains(0));
      expect(progressProvider.completedLessons, contains(1));
      expect(progressProvider.completedLessons.length, 2);
    });

    test('should check if a lesson is completed', () async {
      await progressProvider.initialize();
      await progressProvider.markLessonCompleted(0);

      expect(progressProvider.isLessonCompleted(0), isTrue);
      expect(progressProvider.isLessonCompleted(1), isFalse);
    });

    test('should mark lesson as completed and notify listeners', () async {
      await progressProvider.initialize();

      var notified = false;
      progressProvider.addListener(() {
        notified = true;
      });

      await progressProvider.markLessonCompleted(0);

      expect(progressProvider.isLessonCompleted(0), isTrue);
      expect(notified, isTrue);
    });

    test('should save quiz score', () async {
      await progressProvider.initialize();
      await progressProvider.saveQuizScore(0, 9, 10);

      final score = await progressProvider.getBestScore(0);
      expect(score, 90);
    });

    test('should cache best scores', () async {
      await progressProvider.initialize();
      await progressProvider.saveQuizScore(0, 8, 10);

      // First call should fetch from service
      final score1 = await progressProvider.getBestScore(0);
      // Second call should use cached value
      final score2 = await progressProvider.getBestScore(0);

      expect(score1, 80);
      expect(score2, 80);
    });

    test('should return null for non-existent score', () async {
      await progressProvider.initialize();
      final score = await progressProvider.getBestScore(99);
      expect(score, isNull);
    });

    test('should get total completed lessons count', () async {
      await progressProvider.initialize();
      await progressProvider.markLessonCompleted(0);
      await progressProvider.markLessonCompleted(1);

      expect(progressProvider.totalCompletedLessons, 2);
    });

    test('should calculate overall progress', () async {
      await progressProvider.initialize();
      await progressProvider.markLessonCompleted(0);
      await progressProvider.markLessonCompleted(1);

      final progress = progressProvider.getOverallProgress(8);
      expect(progress, 25); // 2 out of 8 = 25%
    });

    test('should clear all progress', () async {
      await progressProvider.initialize();
      await progressProvider.markLessonCompleted(0);
      await progressProvider.saveQuizScore(0, 10, 10);

      await progressProvider.clearAllProgress();

      expect(progressProvider.completedLessons, isEmpty);
      expect(progressProvider.totalCompletedLessons, 0);
    });

    test('should notify listeners when clearing progress', () async {
      await progressProvider.initialize();
      await progressProvider.markLessonCompleted(0);

      var notified = false;
      progressProvider.addListener(() {
        notified = true;
      });

      await progressProvider.clearAllProgress();

      expect(notified, isTrue);
    });
  });
}
