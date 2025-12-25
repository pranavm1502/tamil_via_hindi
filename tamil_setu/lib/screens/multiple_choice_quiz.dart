import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';

/// Multiple choice quiz view for testing knowledge.
class MultipleChoiceQuiz extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;

  const MultipleChoiceQuiz({
    super.key,
    required this.words,
    required this.lessonIndex,
  });

  @override
  State<MultipleChoiceQuiz> createState() => _MultipleChoiceQuizState();
}

class _MultipleChoiceQuizState extends State<MultipleChoiceQuiz> {
  int currentIndex = 0;
  int score = 0;
  late List<WordPair> shuffledWords;
  late List<String> currentOptions;
  String? selectedAnswer;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
    _generateOptions();
  }

  void _generateOptions() {
    final random = Random();
    final correctAnswer = shuffledWords[currentIndex].tamil;

    // Get 3 wrong answers
    final otherWords = List<WordPair>.from(widget.words)
      ..removeWhere((w) => w.tamil == correctAnswer);

    if (otherWords.length < 3) {
      // If not enough other words, use some duplicates with markers
      otherWords.addAll(widget.words.take(3));
    }

    final wrongAnswers =
        (otherWords.toList()..shuffle()).take(3).map((w) => w.tamil).toList();

    // Combine and shuffle options
    currentOptions = [correctAnswer, ...wrongAnswers]..shuffle(random);
  }

  void _selectAnswer(String answer) {
    if (showResult) return;

    setState(() {
      selectedAnswer = answer;
      showResult = true;

      if (answer == shuffledWords[currentIndex].tamil) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentIndex < shuffledWords.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        showResult = false;
        _generateOptions();
      });
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
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
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    progressProvider.saveQuizScore(
        widget.lessonIndex, score, shuffledWords.length);

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
              setState(() {
                currentIndex = 0;
                score = 0;
                selectedAnswer = null;
                showResult = false;
                shuffledWords.shuffle();
                _generateOptions();
              });
            },
            child: const Text('Retry'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
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
      return const Center(
        child: Text('No words available for quiz.'),
      );
    }

    final currentWord = shuffledWords[currentIndex];
    final correctAnswer = currentWord.tamil;

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
            'Question ${currentIndex + 1}/${shuffledWords.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),

          // Question card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'What is the Tamil translation for:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentWord.hindi,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...currentOptions.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = selectedAnswer == option;
            final isCorrect = option == correctAnswer;

            Color? backgroundColor;
            Color? borderColor;

            if (showResult && isSelected) {
              backgroundColor = isCorrect
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2);
              borderColor = isCorrect ? Colors.green : Colors.red;
            } else if (showResult && isCorrect) {
              backgroundColor = Colors.green.withValues(alpha: 0.1);
              borderColor = Colors.green;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _selectAnswer(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Theme.of(context).cardColor,
                    border: Border.all(
                      color: borderColor ?? Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showResult && (isSelected || isCorrect))
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Next button
          if (showResult)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _nextQuestion,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                currentIndex < shuffledWords.length - 1
                    ? 'Next Question'
                    : 'See Results',
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }
}
