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
    test('should initialize with default locked state (Level 1 open)', () async {
      await progressProvider.loadProgress();
      expect(progressProvider.unlockedLevel, 1);
      expect(progressProvider.totalCompletedLessons, 0);
    });

    test('should load existing progress from storage', () async {
      // Setup mock storage: Level 2 unlocked, Lesson 0 completed
      SharedPreferences.setMockInitialValues({
        'unlockedLevel': 2,
        'completedLessons': ['0'],
      });

      await progressProvider.loadProgress();

      expect(progressProvider.unlockedLevel, 2);
      expect(progressProvider.totalCompletedLessons, 1);
      expect(progressProvider.isLessonCompleted(0), isTrue);
    });

    test('should lock future levels correctly', () async {
      await progressProvider.loadProgress();
      // unlockedLevel is 1. 
      // Index 0 (Level 1) is unlocked. Index 1 (Level 2) is locked.
      expect(progressProvider.isLessonLocked(0), isFalse); 
      expect(progressProvider.isLessonLocked(1), isTrue);
    });

    test('should NOT mark completed if score is below 80%', () async {
      await progressProvider.loadProgress();
      
      // 7 out of 10 is 70% (Fail)
      await progressProvider.saveQuizScore(0, 7, 10);

      expect(progressProvider.isLessonCompleted(0), isFalse);
      expect(progressProvider.unlockedLevel, 1); // Still on level 1
    });

    test('should mark completed AND unlock next level if score >= 80%', () async {
      await progressProvider.loadProgress();

      // 8 out of 10 is 80% (Pass)
      await progressProvider.saveQuizScore(0, 8, 10);

      expect(progressProvider.isLessonCompleted(0), isTrue);
      expect(progressProvider.unlockedLevel, 2); // Next level unlocked!
    });

    test('should calculate overall progress correctly', () async {
      await progressProvider.loadProgress();
      
      // Pass two lessons
      await progressProvider.saveQuizScore(0, 10, 10);
      await progressProvider.saveQuizScore(1, 10, 10);

      // 2 completed out of 4 total = 50%
      final progress = progressProvider.getOverallProgress(4);
      expect(progress, 50.0);
    });

    test('should clear all progress', () async {
      await progressProvider.loadProgress();
      await progressProvider.saveQuizScore(0, 10, 10); // Unlock level 2

      await progressProvider.clearAllProgress();

      expect(progressProvider.unlockedLevel, 1);
      expect(progressProvider.totalCompletedLessons, 0);
    });
  });
}