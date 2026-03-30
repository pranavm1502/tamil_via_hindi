import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_setu/widgets/word_card.dart';

void main() {
  group('WordCard', () {
    testWidgets('renders Hindi, Tamil, and pronunciation text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCard(
              hindi: 'नमस्ते',
              tamil: 'வணக்கம்',
              pronunciation: 'वणक्कम्',
              onPlayAudio: () {},
            ),
          ),
        ),
      );

      expect(find.text('நமस्ते'), findsNothing);
      expect(find.text('நமस्ते'), findsNothing);
      expect(find.text('नमस्ते'), findsOneWidget);
      expect(find.text('வணக்கம்'), findsOneWidget);
      expect(find.text('(वणक्कम्)'), findsOneWidget);
    });

    testWidgets('renders no image widget when imagePath is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCard(
              hindi: 'नमस्ते',
              tamil: 'வணக்கம்',
              pronunciation: 'वणक्कम्',
              onPlayAudio: () {},
              // imagePath not provided — defaults to null
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('word-card-image')), findsNothing);
    });

    testWidgets('renders Image.asset when imagePath is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCard(
              hindi: 'नमस्ते',
              tamil: 'வணக்கம்',
              pronunciation: 'वणक्कम्',
              onPlayAudio: () {},
              imagePath: 'assets/images/words/namaste.png',
            ),
          ),
        ),
      );

      // Consume expected missing-asset error from unit test environment
      // (assets are only available in integration tests / on-device builds)
      tester.takeException();

      // The image widget should be present in the tree by its key
      expect(find.byKey(const ValueKey('word-card-image')), findsOneWidget);

      // Verify the semanticLabel is set to the Hindi word
      final image = tester.widget<Image>(
          find.byKey(const ValueKey('word-card-image')));
      expect(image.semanticLabel, 'नमस्ते');
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('image container has correct 150 dp height when imagePath provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCard(
              hindi: 'नमस्ते',
              tamil: 'வணக்கம்',
              pronunciation: 'वणक्कम्',
              onPlayAudio: () {},
              imagePath: 'assets/images/words/namaste.png',
            ),
          ),
        ),
      );

      // Consume expected missing-asset error from unit test environment
      tester.takeException();

      final sizebox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(const ValueKey('word-card-image')),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizebox.height, 150);
    });
  });
}
