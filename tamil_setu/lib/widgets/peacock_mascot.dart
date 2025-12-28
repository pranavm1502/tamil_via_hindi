import 'package:flutter/material.dart';

enum MascotState { guide, celebrate, confused }

class PeacockMascot extends StatelessWidget {
  final String message;
  final MascotState state;

  const PeacockMascot({super.key, required this.message, this.state = MascotState.guide});

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          assetPath,
          height: 80,
          errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.stars, size: 50, color: Colors.orange),
        ),
      ],
    );
  }
}