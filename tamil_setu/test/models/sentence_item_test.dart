import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/sentence_item.dart';

void main() {
  group('SentenceItem', () {
    test('should parse from JSON correctly', () {
      final json = {
        'hindi': 'मुझे पानी चाहिए',
        'tamil': 'எனக்கு தண்ணீர் வேண்டும்',
        'pronunciation': 'एनक्कु तण्णीर् वेण्डुम्',
        'audio_path': 'assets/audio/s1_water.mp3',
        'tags': ['lesson:1', 'topic:survival_basics'],
      };

      final item = SentenceItem.fromJson(json);

      expect(item.hindi, 'मुझे पानी चाहिए');
      expect(item.tamil, 'எனக்கு தண்ணீர் வேண்டும்');
      expect(item.audioPath, 'assets/audio/s1_water.mp3');
      expect(item.tags, ['lesson:1', 'topic:survival_basics']);
      expect(item.imagePath, isNull);
    });

    group('imagePath', () {
      test('is populated when image_path is present in JSON', () {
        final json = {
          'hindi': 'मुझे पानी चाहिए',
          'tamil': 'எனக்கு தண்ணீர் வேண்டும்',
          'pronunciation': 'एनक्कु तण्णीर् वेण्डुम्',
          'audio_path': 'assets/audio/s1_water.mp3',
          'tags': <String>[],
          'image_path': 'assets/images/words/pani.png',
        };

        final item = SentenceItem.fromJson(json);

        expect(item.imagePath, 'assets/images/words/pani.png');
      });

      test('is null when image_path key is absent from JSON', () {
        final json = {
          'hindi': 'मुझे पानी चाहिए',
          'tamil': 'எனக்கு தண்ணீர் வேண்டும்',
          'pronunciation': 'एनक्कु तण्णीर् वेण्डुम्',
          'audio_path': 'assets/audio/s1_water.mp3',
          'tags': <String>[],
        };

        final item = SentenceItem.fromJson(json);

        expect(item.imagePath, isNull);
      });

      test('is null when image_path is explicitly null in JSON', () {
        final json = {
          'hindi': 'मुझे पानी चाहिए',
          'tamil': 'எனக்கு தண்ணீர் வேண்டும்',
          'pronunciation': 'एनक्कु तण्णीर् वेण्डुम्',
          'audio_path': 'assets/audio/s1_water.mp3',
          'tags': <String>[],
          'image_path': null,
        };

        final item = SentenceItem.fromJson(json);

        expect(item.imagePath, isNull);
      });
    });
  });
}
