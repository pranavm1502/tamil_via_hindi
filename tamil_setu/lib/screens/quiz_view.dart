import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';

class QuizView extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;

  const QuizView({
    super.key,
    required this.words,
    required this.lessonIndex,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int currentIndex = 0;
  int score = 0;
  bool showAnswer = false;
  late List<WordPair> shuffledWords;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String path) async {
    try {
      final cleanPath = path.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
    }
  }

  void _nextCard(bool knewIt) {
    if (knewIt) score++;

    setState(() {
      if (currentIndex < shuffledWords.length - 1) {
        currentIndex++;
        showAnswer = false;
      } else {
        _showResultDialog();
      }
    });
  }

  // This method was previously unused; now it's called by the "Retry" button
  void _restartQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      showAnswer = false;
      shuffledWords.shuffle();
    });
  }

  void _showResultDialog() {
    // 1. Calculate percentage (Fixes 'unused variable' warning)
    final percentage = (score / shuffledWords.length * 100).round();

    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = 'Excellent! बहुत अच्छा!';
      icon = Icons.star;
      color = Colors.green;
    } else if (percentage >= 60) {
      message = 'Good job! अच्छा!';
      icon = Icons.thumb_up;
      color = Colors.orange;
    } else {
      message = 'Keep practicing! अभ्यास करते रहो!';
      icon = Icons.school;
      color = Colors.blue;
    }

    // Save progress
    Provider.of<ProgressProvider>(context, listen: false)
        .saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You scored $score out of ${shuffledWords.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            // 2. Display percentage (Fixes 'unused variable' warning)
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restartQuiz(); // 3. Fixes 'unused element' warning
            },
            child: const Text('Retry Quiz'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to lesson screen
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledWords.isEmpty) {
      return const Center(child: Text('No words available.'));
    }

    final currentWord = shuffledWords[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / shuffledWords.length,
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          Text('Question ${currentIndex + 1}/${shuffledWords.length}',
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            elevation: 8,
            child: Container(
              height: 250,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Translate this Hindi word:',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    currentWord.hindi,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),
                  if (showAnswer) ...[
                    Text(
                      currentWord.tamil,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    Text(
                      currentWord.pronunciation,
                      style:
                          const TextStyle(fontSize: 20, color: Colors.blueGrey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up,
                          size: 30, color: Colors.blue),
                      onPressed: () => _playAudio(currentWord.audioPath),
                    ),
                  ] else
                    const Text('?',
                        style: TextStyle(fontSize: 40, color: Colors.orange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!showAnswer)
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () {
                setState(() => showAnswer = true);
                _playAudio(currentWord.audioPath);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Answer', style: TextStyle(fontSize: 18)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Wrong'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Correct'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
