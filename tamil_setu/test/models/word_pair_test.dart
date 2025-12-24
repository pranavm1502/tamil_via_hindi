import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/models/word_pair.dart';

void main() {
  group('WordPair', () {
    test('should create a WordPair with all required fields', () {
      final wordPair = WordPair(
        hindi: 'Namaste',
        tamil: 'Vanakkam',
        pronunciation: 'वनक्कम',
      );

      expect(wordPair.hindi, 'Namaste');
      expect(wordPair.tamil, 'Vanakkam');
      expect(wordPair.pronunciation, 'वनक्कम');
    });

    test('should allow creating multiple WordPair instances', () {
      final pair1 = WordPair(
        hindi: 'Hello',
        tamil: 'Vanakkam',
        pronunciation: 'वनक्कम',
      );
      final pair2 = WordPair(
        hindi: 'Goodbye',
        tamil: 'Poitu varen',
        pronunciation: 'पोइतु वरेन',
      );

      expect(pair1.hindi, isNot(equals(pair2.hindi)));
      expect(pair1.tamil, isNot(equals(pair2.tamil)));
    });
  });
}
