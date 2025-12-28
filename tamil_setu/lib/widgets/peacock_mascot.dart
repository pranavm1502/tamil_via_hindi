import 'package:flutter/material.dart';

enum MascotState { guide, celebrate, confused }

class PeacockMascot extends StatelessWidget {
  final String message;
  final MascotState state;

  const PeacockMascot({
    super.key, 
    required this.message, 
    this.state = MascotState.guide
  });

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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack, // Gives it a little "bounce"
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // Slides up by 20 pixels
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Dynamic Speech Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mascot Image
          Image.asset(
            assetPath,
            height: 90,
            // Fallback icon if the image fails to load
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.star, size: 50, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}