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
          audioPath: 'assets/audio/l1.mp3', // TODO: this is currently not being checked
        ),
      ];

      final lesson = Lesson(
        level: 1, // Now required
        title: 'Basics',
        description: 'Basic greetings',
        words: words,
      );

      expect(lesson.level, 1);
      expect(lesson.title, 'Basics');
      expect(lesson.words.length, 1);
    });

    test('should parse from JSON correctly', () {
      final json = {
        'level': 1,
        'title': 'Basics',
        'description': 'Start with Namaste',
        'words': [
          {
            'tamil': 'வணக்கம்',
            'hindi': 'नमस्ते',
            'pronunciation': 'वणक्कम्',
            'audio_path': 'assets/audio/l1.mp3'
          }
        ]
      };

      final lesson = Lesson.fromJson(json);

      expect(lesson.level, 1);
      expect(lesson.title, 'Basics');
      expect(lesson.words.first.tamil, 'வணக்கம்');
      expect(lesson.words.first.audioPath, 'assets/audio/l1.mp3');
    });
  });
}
