import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/services/quiz_score.dart';

void main() {
  group('QuizScore.percent', () {
    group('lower bound — 0%', () {
      test('flashcard quiz: 0 correct out of N returns 0', () {
        expect(QuizScore.percent(0, 10), 0);
      });

      test('MCQ quiz: 0 correct out of N returns 0', () {
        expect(QuizScore.percent(0, 5), 0);
      });

      test('checkpoint quiz: 0 correct out of N returns 0', () {
        expect(QuizScore.percent(0, 20), 0);
      });

      test('sentence builder: 0 correct out of N returns 0', () {
        expect(QuizScore.percent(0, 8), 0);
      });
    });

    group('upper bound — 100%', () {
      test('flashcard quiz: all correct returns 100', () {
        expect(QuizScore.percent(10, 10), 100);
      });

      test('MCQ quiz: all correct returns 100', () {
        expect(QuizScore.percent(5, 5), 100);
      });

      test('checkpoint quiz: all correct returns 100', () {
        expect(QuizScore.percent(20, 20), 100);
      });

      test('sentence builder: all correct returns 100', () {
        expect(QuizScore.percent(8, 8), 100);
      });
    });

    group('always within 0–100', () {
      test('partial score is between 0 and 100', () {
        final result = QuizScore.percent(7, 10);
        expect(result, inInclusiveRange(0, 100));
        expect(result, 70);
      });

      test('passing threshold (80%) is in range', () {
        final result = QuizScore.percent(8, 10);
        expect(result, inInclusiveRange(0, 100));
        expect(result, 80);
      });

      test('just below passing threshold (70%) is in range', () {
        final result = QuizScore.percent(7, 10);
        expect(result, inInclusiveRange(0, 100));
      });

      test('single correct out of many is in range', () {
        final result = QuizScore.percent(1, 20);
        expect(result, inInclusiveRange(0, 100));
      });

      test('rounds correctly — does not produce 101 due to floating point', () {
        // 10/10 == 1.0 exactly; verify no floating-point edge case creeps above 100
        for (final total in [1, 2, 3, 5, 7, 10, 13, 20]) {
          final result = QuizScore.percent(total, total);
          expect(result, 100,
              reason: 'all-correct score should be exactly 100 for total=$total');
        }
      });
    });

    group('invalid inputs fire assert', () {
      test('score greater than total asserts (corrupted state)', () {
        expect(
          () => QuizScore.percent(11, 10),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative score asserts', () {
        expect(
          () => QuizScore.percent(-1, 10),
          throwsA(isA<AssertionError>()),
        );
      });

      test('zero total asserts (division by zero guard)', () {
        expect(
          () => QuizScore.percent(0, 0),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}
