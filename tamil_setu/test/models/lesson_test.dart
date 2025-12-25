import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/lesson.dart';
import 'package:tamil_setu/models/word_pair.dart';

void main() {
  group('Lesson', () {
    test('should create a Lesson with all required fields', () {
      final words = [
        WordPair(
          hindi: 'Namaste',
          tamil: 'Vanakkam',
          pronunciation: 'वनक्कम',
        ),
      ];

      final lesson = Lesson(
        title: 'Basics',
        description: 'Basic greetings',
        words: words,
      );

      expect(lesson.title, 'Basics');
      expect(lesson.description, 'Basic greetings');
      expect(lesson.words, words);
      expect(lesson.words.length, 1);
    });

    test('should allow empty word list', () {
      final lesson = Lesson(
        title: 'Empty Lesson',
        description: 'A lesson with no words',
        words: [],
      );

      expect(lesson.words, isEmpty);
    });

    test('should allow multiple words in a lesson', () {
      final words = [
        WordPair(hindi: 'Hello', tamil: 'Vanakkam', pronunciation: 'वनक्कम'),
        WordPair(
            hindi: 'Goodbye',
            tamil: 'Poitu varen',
            pronunciation: 'पोइतु वरेन'),
      ];

      final lesson = Lesson(
        title: 'Greetings',
        description: 'Common greetings',
        words: words,
      );

      expect(lesson.words.length, 2);
      expect(lesson.words[0].hindi, 'Hello');
      expect(lesson.words[1].hindi, 'Goodbye');
    });
  });
}
