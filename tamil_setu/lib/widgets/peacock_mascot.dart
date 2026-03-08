import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Visual states for the mascot illustration.
enum MascotState { guide, celebrate, confused }

/// Layout options for the mascot + speech bubble.
enum MascotLayout { inline, overlap }

/// Speech bubble + mascot illustration with a gentle entrance animation.
class PeacockMascot extends StatelessWidget {
  final String message;
  final MascotState state;
  final double imageSize;
  final double fontSize;
  final EdgeInsets bubblePadding;
  final Color? bubbleColor;
  final MascotLayout layout;
  final double? overlapInset;
  final Offset imageOffset;
  final bool enableTestAnimation;

  const PeacockMascot(
      {super.key,
      required this.message,
      this.state = MascotState.guide,
      this.imageSize = 96,
      this.fontSize = 15,
      this.bubblePadding = const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      this.bubbleColor,
      this.layout = MascotLayout.inline,
      this.overlapInset,
      this.imageOffset = Offset.zero,
      this.enableTestAnimation = false});

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  String _preventOrphanedPunctuation(String value) {
    // Insert a word-joiner before sentence-ending punctuation to avoid orphaned glyphs.
    return value.replaceAllMapped(
      RegExp(r'([A-Za-z0-9])([.!?])'),
      (match) => '${match[1]}\u2060${match[2]}',
    );
  }

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (state) {
      case MascotState.celebrate:
        assetPath = 'assets/images/peacock_celebrator.png';
        break;
      case MascotState.confused:
        assetPath = 'assets/images/peacock_retry.png';
        break;
      default:
        assetPath = 'assets/images/peacock_guide.png';
    }

    final safeMessage = _preventOrphanedPunctuation(message);

    final content = layout == MascotLayout.inline
        ? Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dynamic Speech Bubble
              Expanded(
                child: Container(
                  padding: bubblePadding,
                  decoration: BoxDecoration(
                    color: bubbleColor ?? Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    safeMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.left,
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mascot Image
              Image.asset(
                assetPath,
                height: imageSize,
                semanticLabel: 'Peacock mascot',
                // Fallback icon if the image fails to load
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.star, size: 50, color: Colors.orange),
              ),
            ],
          )
        : Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: double.infinity,
                padding: bubblePadding.copyWith(
                  right: (overlapInset ?? imageSize * 0.55),
                ),
                decoration: BoxDecoration(
                  color: bubbleColor ?? Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Text(
                  safeMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.left,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
              ),
              Transform.translate(
                offset: imageOffset,
                child: Image.asset(
                  assetPath,
                  height: imageSize,
                  semanticLabel: 'Peacock mascot',
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.star, size: 50, color: Colors.orange),
                ),
              ),
            ],
          );

    // Skip animations in tests to avoid golden capture hangs.
    if (_isTestEnvironment() && !enableTestAnimation) {
      return Semantics(
        container: true,
        label: 'Mascot message: $message',
        child: content,
      );
    }

    return Semantics(
      container: true,
      label: 'Mascot message: $message',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: content,
      ),
    );
  }
}
