import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; 
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
  final AudioPlayer _audioPlayer = AudioPlayer(); 

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
      // Fallback for small lessons
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
    // Save progress
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    progressProvider.saveQuizScore(
        widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
          title: const Text('Quiz Complete!'),
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

  // START CHANGE: Helper to get WordPair from the option string
  WordPair? _getWordPairForOption(String tamilOption) {
    try {
      return widget.words.firstWhere((w) => w.tamil == tamilOption);
    } catch (_) {
      return null;
    }
  }
  // END CHANGE

  @override
  Widget build(BuildContext context) {
    if (shuffledWords.isEmpty) return const Center(child: Text('No words.'));

    final currentWord = shuffledWords[currentIndex];
    
    // Helper to determine the color of the option
    Color? getOptionColor(String option) {
      if (!showResult) return null;
      if (option == currentWord.tamil) return Colors.green[100];
      if (option == selectedAnswer) return Colors.red[100];
      return null;
    }

    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  LinearProgressIndicator(
                      value: (currentIndex + 1) / shuffledWords.length),
                  const SizedBox(height: 16),
                  Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          currentWord.hindi,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
              
              // START CHANGE: Options mapping
              Column(
                children: currentOptions.asMap().entries.map((entry) {
                final option = entry.value;
                final pair = _getWordPairForOption(option); // Look up the pair

                // Fallback for safety, though should not happen with correct data
                if (pair == null) return const SizedBox.shrink(); 

                return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                        onTap: () => _selectAnswer(option),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: getOptionColor(option) ?? Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: showResult && option == currentWord.tamil 
                                ? Colors.green 
                                : (showResult && option == selectedAnswer && option != currentWord.tamil
                                    ? Colors.red 
                                    : Colors.grey.shade300),
                              width: 2,
                            ),
                          ),
                          child: Row( // Use a Row to combine the scripts
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pair.tamil, // Tamil Script
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${pair.pronunciation})', // Hindi Transliteration
                                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        )));
              }).toList(),
              ),
              // END CHANGE

              if (showResult)
                FilledButton(
                    onPressed: _nextQuestion, 
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text('Next Question', style: TextStyle(fontSize: 18)))
            ]));
  }
}