import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // Added
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';
import '../widgets/peacock_mascot.dart';

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
  late ConfettiController _confettiController; // Added

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    shuffledWords = List.from(widget.words)..shuffle();
    _generateOptions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
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
    final percentage = (score / shuffledWords.length * 100).round();
    
    if (percentage >= 80) {
      _confettiController.play();
    }

    Provider.of<ProgressProvider>(context, listen: false)
        .saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PeacockMascot(
                    message: percentage >= 80 ? 'Quiz Complete! शानदार!' : 'Good attempt! और अभ्यास करें!',
                    state: percentage >= 80 ? MascotState.celebrate : MascotState.confused,
                  ),
                  const SizedBox(height: 20),
                  Text('You scored $score out of ${shuffledWords.length}', style: const TextStyle(fontSize: 18)),
                  Text('$percentage%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: percentage >= 80 ? Colors.green : Colors.orange)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _confettiController.stop();
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
                    _confettiController.stop();
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Finish'),
                ),
              ]),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
          ),
        ],
      ),
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
    
    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / shuffledWords.length,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 30),
                  Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text('Choose the correct Tamil translation:', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 10),
                            Text(
                              currentWord.hindi,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )),
                ],
              ),
              
              Column(
                children: currentOptions.map((option) {
                final pair = _getWordPairForOption(option);
                if (pair == null) return const SizedBox.shrink();

                bool isCorrect = option == currentWord.tamil;
                bool isSelected = option == selectedAnswer;

                return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(15),
                        child: Container( 
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !showResult ? Colors.white : (isCorrect ? Colors.green.shade50 : (isSelected ? Colors.red.shade50 : Colors.white)),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: !showResult ? Colors.grey.shade300 : (isCorrect ? Colors.green : (isSelected ? Colors.red : Colors.grey.shade300)),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                pair.tamil,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: showResult && !isCorrect ? Colors.grey : Colors.black87
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(${pair.pronunciation})',
                                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        )));
              }).toList(),
              ),
              
              if (showResult)
                FilledButton(
                    onPressed: _nextQuestion, 
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
                    child: const Text('Continue', style: TextStyle(fontSize: 20)))
              else
                const SizedBox(height: 50), 
            ]));
  }
}