import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/word_pair.dart';

void main() {
  group('WordPair', () {
    test('should create a WordPair with all required fields', () {
      final wordPair = WordPair(
        hindi: 'Namaste',
        tamil: 'Vanakkam',
        pronunciation: 'वनक्कम',
        audioPath: 'assets/audio/l1_greet.mp3', // Now required
      );

      expect(wordPair.hindi, 'Namaste');
      expect(wordPair.tamil, 'Vanakkam');
      expect(wordPair.pronunciation, 'वनक्कम');
      expect(wordPair.audioPath, 'assets/audio/l1_greet.mp3');
      expect(wordPair.imagePath, isNull);
    });

    test('should parse from JSON correctly', () {
      final json = {
        'tamil': 'வணக்கம்',
        'hindi': 'नमस्ते',
        'pronunciation': 'वणक्कम्',
        'audio_path': 'assets/audio/l1_namaste.mp3'
      };

      final pair = WordPair.fromJson(json);

      expect(pair.tamil, 'வணக்கம்');
      expect(pair.hindi, 'नमस्ते');
      expect(pair.pronunciation, 'वणक्कम्');
      expect(pair.audioPath, 'assets/audio/l1_namaste.mp3');
    });

    group('imagePath', () {
      test('is populated when image_path is present in JSON', () {
        final json = {
          'hindi': 'नमस्ते',
          'tamil': 'வணக்கம்',
          'pronunciation': 'वणक्कम्',
          'audio_path': 'assets/audio/l1_namaste.mp3',
          'image_path': 'assets/images/words/namaste.png',
        };

        final pair = WordPair.fromJson(json);

        expect(pair.imagePath, 'assets/images/words/namaste.png');
      });

      test('is null when image_path key is absent from JSON', () {
        final json = {
          'hindi': 'नमस्ते',
          'tamil': 'வணக்கம்',
          'pronunciation': 'वणक्कम्',
          'audio_path': 'assets/audio/l1_namaste.mp3',
        };

        final pair = WordPair.fromJson(json);

        expect(pair.imagePath, isNull);
      });

      test('is null when image_path is explicitly null in JSON', () {
        final json = {
          'hindi': 'नमस्ते',
          'tamil': 'வணக்கம்',
          'pronunciation': 'वणक्कम्',
          'audio_path': 'assets/audio/l1_namaste.mp3',
          'image_path': null,
        };

        final pair = WordPair.fromJson(json);

        expect(pair.imagePath, isNull);
      });
    });
  });
}
