import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';

/// Quiz view for testing knowledge of word pairs.
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

  @override
  void initState() {
    super.initState();
    // Shuffle words for varied quiz experience
    shuffledWords = List.from(widget.words)..shuffle();
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

  void _restartQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      showAnswer = false;
      shuffledWords.shuffle();
    });
  }

  void _showResultDialog() {
    final percentage = (score / shuffledWords.length * 100).round();
    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = "Excellent! बहुत अच्छा!";
      icon = Icons.star;
      color = Colors.green;
    } else if (percentage >= 60) {
      message = "Good job! अच्छा!";
      icon = Icons.thumb_up;
      color = Colors.orange;
    } else {
      message = "Keep practicing! अभ्यास करते रहो!";
      icon = Icons.school;
      color = Colors.blue;
    }

    // Save quiz score to progress
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    progressProvider.saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: const Text("Quiz Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You scored $score out of ${shuffledWords.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "$percentage%",
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
              _restartQuiz();
            },
            child: const Text("Retry Quiz"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledWords.isEmpty) {
      return const Center(
        child: Text("No words available for quiz."),
      );
    }

    final currentWord = shuffledWords[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentIndex + 1) / shuffledWords.length,
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          Text(
            "Question ${currentIndex + 1}/${shuffledWords.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Quiz card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 200,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Translate this Hindi word:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentWord.hindi,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 30),
                  if (showAnswer) ...[
                    Text(
                      currentWord.tamil,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      currentWord.pronunciation,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ] else
                    const Text(
                      "?",
                      style: TextStyle(fontSize: 40, color: Colors.orange),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Action buttons
          if (!showAnswer)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () => setState(() => showAnswer = true),
              icon: const Icon(Icons.visibility),
              label: const Text(
                "Show Answer",
                style: TextStyle(fontSize: 18),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () => _nextCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text("Wrong"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () => _nextCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text("Correct"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
