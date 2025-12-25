import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer(); // Add player

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
    _generateOptions();
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

  void _generateOptions() {
    final random = Random();
    final correctAnswer = shuffledWords[currentIndex].tamil;

    // Get 3 wrong answers
    final otherWords = List<WordPair>.from(widget.words)
      ..removeWhere((w) => w.tamil == correctAnswer);

    if (otherWords.length < 3) {
      otherWords.addAll(widget.words.take(3));
    }

    final wrongAnswers =
        (otherWords.toList()..shuffle()).take(3).map((w) => w.tamil).toList();

    currentOptions = [correctAnswer, ...wrongAnswers]..shuffle(random);
  }

  void _selectAnswer(String answer) {
    if (showResult) return;

    setState(() {
      selectedAnswer = answer;
      showResult = true;

      final currentWord = shuffledWords[currentIndex];
      if (answer == currentWord.tamil) {
        score++;
        _playAudio(currentWord.audioPath); // Play audio if correct!
      }
    });
  }

  // ... (The rest of your logic: _nextQuestion, _showFinalResults, build method)
  // ... (Copy from your uploaded file, no changes needed below this point)

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

  // Note: Ensure _showFinalResults uses the passed lessonIndex correctly as you did before.
  void _showFinalResults() {
    // (Your existing code here)
    // Save progress
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    progressProvider.saveQuizScore(
        widget.lessonIndex, score, shuffledWords.length);

    // (Your existing dialog code here)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
          title: const Text('Quiz Complete!'),
          // ... rest of your UI code
          content: Text('You scored $score out of ${shuffledWords.length}'),
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
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // (Your existing build method code is perfectly fine)
    // Just ensure you import the AudioPlayer package at the top.
    if (shuffledWords.isEmpty) return const Center(child: Text('No words.'));

    // ... Rest of your UI code
    final currentWord = shuffledWords[currentIndex];
    // final correctAnswer = currentWord.tamil;

    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
            // ... Your existing layout code
            children: [
              LinearProgressIndicator(
                  value: (currentIndex + 1) / shuffledWords.length),
              // ...
              Card(
                  child: Column(children: [
                Text(currentWord.hindi, style: const TextStyle(fontSize: 28)),
              ])),
              // ... Options mapping
              ...currentOptions.asMap().entries.map((entry) {
                final option = entry.value;
                return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                        onTap: () => _selectAnswer(option),
                        // ... rest of styling
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          // ... decoration
                          child: Text(option),
                        )));
              }),
              // ... Next button
              if (showResult)
                FilledButton(
                    onPressed: _nextQuestion, child: const Text('Next'))
            ]));
  }
}
