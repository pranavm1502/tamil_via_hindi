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
        _playAudio(currentWord.audioPath); 
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

  WordPair? _getWordPairForOption(String tamilOption) {
    try {
      return widget.words.firstWhere((w) => w.tamil == tamilOption);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledWords.isEmpty) return const Center(child: Text('No words.'));

    final currentWord = shuffledWords[currentIndex];
    
    Color getOptionColor(String option) {
      if (!showResult) return Colors.white;
      if (option == currentWord.tamil) return Colors.green.shade100;
      if (option == selectedAnswer) return Colors.red.shade100;
      return Colors.white;
    }
    
    Color getBorderColor(String option) {
      if (!showResult) return Colors.grey.shade300;
      if (option == currentWord.tamil) return Colors.green.shade600;
      if (option == selectedAnswer && option != currentWord.tamil) return Colors.red.shade600;
      return Colors.grey.shade300;
    }


    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / shuffledWords.length,
                      backgroundColor: Colors.grey[300],
                      minHeight: 10,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Question Card
                  Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text('Choose the correct Tamil translation:', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 10),
                            Text(
                              currentWord.hindi,
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
              
              // Options
              Column(
                children: currentOptions.asMap().entries.map((entry) {
                final option = entry.value;
                final pair = _getWordPairForOption(option);

                if (pair == null) return const SizedBox.shrink(); 

                return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(15),
                        child: AnimatedContainer( 
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: getOptionColor(option),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: getBorderColor(option),
                              width: 2,
                            ),
                            boxShadow: [
                                BoxShadow(
                                  // FIX: Resolving deprecated 'withOpacity' / 'withValues'
                                  // 0.3 * 255 = 76
                                  color: getBorderColor(option).withAlpha(76), 
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pair.tamil, // Tamil Script
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w800,
                                  color: showResult && option != currentWord.tamil ? Colors.grey.shade600 : Colors.black87
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${pair.pronunciation})', // Hindi Transliteration
                                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        )));
              }).toList(),
              ),
              
              if (showResult)
                FilledButton(
                    onPressed: _nextQuestion, 
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue', style: TextStyle(fontSize: 20)))
            ]));
  }
}