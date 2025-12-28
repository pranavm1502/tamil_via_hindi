import 'package:flutter/material.dart';

class WordCard extends StatelessWidget {
  final String hindi;
  final String tamil;
  final String pronunciation;
  final VoidCallback onPlayAudio;

  const WordCard({
    super.key,
    required this.hindi,
    required this.tamil,
    required this.pronunciation,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hindi Section (Question)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(hindi, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          // Tamil Section (Answer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap( // Wrap is the secret to fixing overflow
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  tamil,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.deepOrange),
                ),
                Text(
                  '($pronunciation)',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blue, size: 30),
                  onPressed: onPlayAudio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}