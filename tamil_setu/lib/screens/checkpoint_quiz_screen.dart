import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/checkpoint.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';
import '../providers/content_provider.dart';
import '../widgets/peacock_mascot.dart';

class CheckpointQuizScreen extends StatefulWidget {
  final Checkpoint checkpoint;

  const CheckpointQuizScreen({super.key, required this.checkpoint});

  @override
  State<CheckpointQuizScreen> createState() => _CheckpointQuizScreenState();
}

class _CheckpointQuizScreenState extends State<CheckpointQuizScreen> {
  int currentIndex = 0;
  int score = 0;
  late List<WordPair> quizWords;
  late List<WordPair> allWords;
  late List<String> currentOptions;
  String? selectedAnswer;
  bool showResult = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadWordsFromLessons();
    _generateOptions();
  }

  void _loadWordsFromLessons() {
    final contentProvider = context.read<ContentProvider>();
    allWords = [];

    // Collect all words from the checkpoint's lesson range
    for (int i = widget.checkpoint.startLessonIndex; i <= widget.checkpoint.endLessonIndex; i++) {
      if (i < contentProvider.lessons.length) {
        allWords.addAll(contentProvider.lessons[i].words);
      }
    }

    // Shuffle and select questionCount words for the quiz
    allWords.shuffle();
    quizWords = allWords.take(widget.checkpoint.questionCount).toList();
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
    final correctAnswer = quizWords[currentIndex].tamil;

    final otherWords = List<WordPair>.from(allWords)
      ..removeWhere((w) => w.tamil == correctAnswer);

    if (otherWords.length < 3) {
      otherWords.addAll(allWords.take(3));
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

      final currentWord = quizWords[currentIndex];
      if (answer == currentWord.tamil) {
        score++;
        _playAudio(currentWord.audioPath);
      }
    });
  }

  void _nextQuestion() {
    if (currentIndex < quizWords.length - 1) {
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
    final percentage = (score / quizWords.length * 100).round();

    if (percentage >= 80) {
      _confettiController.play();
    }

    Provider.of<ProgressProvider>(context, listen: false)
        .saveCheckpointScore(widget.checkpoint.checkpointNumber, score, quizWords.length);

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
                  message: percentage >= 80
                      ? 'Checkpoint Passed! 🎉'
                      : 'Keep practicing! थोड़ा और!',
                  state: percentage >= 80 ? MascotState.celebrate : MascotState.confused,
                ),
                const SizedBox(height: 20),
                Text(
                  'You scored $score out of ${quizWords.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: percentage >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                if (percentage >= 80)
                  const Text(
                    'Next section unlocked!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            actions: [
              if (percentage < 80)
                TextButton(
                  onPressed: () {
                    _confettiController.stop();
                    Navigator.pop(ctx);
                    setState(() {
                      currentIndex = 0;
                      score = 0;
                      selectedAnswer = null;
                      showResult = false;
                      _loadWordsFromLessons();
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
            ],
          ),
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
      return allWords.firstWhere((w) => w.tamil == tamilOption);
    } catch (_) {
      return null;
    }
  }
  @override
  Widget build(BuildContext context) {
    if (quizWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.checkpoint.title)),
        body: const Center(child: Text('No words available for this checkpoint.')),
      );
    }

    final currentWord = quizWords[currentIndex];
    final progress = (currentIndex + 1) / quizWords.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checkpoint.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      // FIX 1: Use LayoutBuilder to respect screen constraints
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              // FIX 2: Ensure the content is at least as tall as the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header & Question Card Section
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${currentIndex + 1} / ${quizWords.length}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.checkpoint.lessonRange,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 30),
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Choose the correct Tamil translation:',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentWord.hindi,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20), // Spacer between card and options

                    // Options Section
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
                              // FIX 3: Changed height to minHeight to allow growth for long text
                              constraints: const BoxConstraints(minHeight: 80),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: !showResult
                                    ? Colors.white
                                    : (isCorrect
                                        ? Colors.green.shade50
                                        : (isSelected ? Colors.red.shade50 : Colors.white)),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: !showResult
                                      ? Colors.grey.shade300
                                      : (isCorrect
                                          ? Colors.green
                                          : (isSelected ? Colors.red : Colors.grey.shade300)),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    pair.tamil,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: showResult && !isCorrect ? Colors.grey : Colors.black87,
                                    ),
                                    // Removed hard constraints here to allow natural wrapping
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '(${pair.pronunciation})',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Action Button Section
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: showResult
                          ? FilledButton(
                              onPressed: _nextQuestion,
                              style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
                              child: const Text('Continue', style: TextStyle(fontSize: 20)),
                            )
                          : const SizedBox(height: 60), // Maintain space even when button hidden
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
