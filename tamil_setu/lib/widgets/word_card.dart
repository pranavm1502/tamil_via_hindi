import 'package:flutter/material.dart';

class WordCard extends StatelessWidget {
  final String hindi;
  final String tamil;
  final String pronunciation;
  final VoidCallback onPlayAudio;
  final String? imagePath;

  const WordCard({
    super.key,
    required this.hindi,
    required this.tamil,
    required this.pronunciation,
    required this.onPlayAudio,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 150,
                child: Image.asset(
                  imagePath!,
                  key: const ValueKey('word-card-image'),
                  fit: BoxFit.contain,
                  semanticLabel: hindi,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Hindi Section (Question)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: imagePath == null
                  ? const BorderRadius.vertical(top: Radius.circular(15))
                  : BorderRadius.zero,
            ),
            child: Text(hindi,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          // Tamil Section (Answer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  tamil,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepOrange),
                ),
                const SizedBox(height: 4),
                Text(
                  '($pronunciation)',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up,
                        color: Colors.blue, size: 30),
                    onPressed: onPlayAudio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
