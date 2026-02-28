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
      this.imageOffset = Offset.zero});

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

    // TweenAnimationBuilder handles the "Pop-in" animation automatically
    return Semantics(
      container: true,
      label: 'Mascot message: $message',
      child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // Gives it a little "bounce"
      builder: (context, value, child) {
        return Opacity(
          // FIX: Clamp the value so it never goes above 1.0 or below 0.0
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: layout == MascotLayout.inline
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Dynamic Speech Bubble
                Flexible(
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
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
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
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
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
            ),
      ),
    );
  }
}
