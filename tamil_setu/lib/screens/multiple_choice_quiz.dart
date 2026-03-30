import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';
import '../providers/review_provider.dart';
import '../providers/mistake_provider.dart';
import '../widgets/peacock_mascot.dart';
import 'package:tamil_setu/services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/tts_service.dart';
import '../services/xp_rules.dart';
import '../services/analytics_service.dart';
import '../services/quiz_score.dart';
import '../services/xp_tracker_service.dart';

class MultipleChoiceQuiz extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;
  final VoidCallback? onComplete;

  const MultipleChoiceQuiz({
    super.key,
    required this.words,
    required this.lessonIndex,
    this.onComplete,
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

  // 1. Changed to nullable to support safe testing
  AudioPlayer? _audioPlayer;
  late ConfettiController _confettiController;
  late DateTime _quizStartTime;
  late DateTime _questionStartTime;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    shuffledWords = List.from(widget.words)..shuffle();
    _generateOptions();

    _quizStartTime = DateTime.now();
    _questionStartTime = _quizStartTime;
    AnalyticsService().logQuizStart(
      lessonIndex: widget.lessonIndex,
      quizType: 'mcq',
    );

    // 2. Initialize AudioPlayer ONLY if NOT in a test environment
    if (!_isTestEnvironment()) {
      _audioPlayer = AudioPlayer();
    }
  }

  // Helper to identify the automated screenshot test environment
  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void dispose() {
    // 3. Null-safe disposal
    _audioPlayer?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _playAudio(WordPair pair) async {
    // 4. Return early if player is null (during tests)
    if (_audioPlayer == null) return;

    try {
      final colloquial = _colloquialTamil(pair.tamil);
      if (pair.tamil.contains('/') && colloquial.isNotEmpty) {
        final spoke = await TtsService().speak(
          colloquial,
          source: 'mcq',
          lessonIndex: widget.lessonIndex,
        );
        if (spoke) return;
      }

      if (pair.audioPath.isEmpty) return;
      final cleanPath = pair.audioPath.replaceFirst('assets/', '');
      // Set speed to 20% faster
      await _audioPlayer!.setPlaybackRate(1.20);
      await _audioPlayer!.stop();
      await _audioPlayer!.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
      AnalyticsService().logAudioPlaybackError(
        source: 'mcq',
        lessonIndex: widget.lessonIndex,
      );
    }
  }

  String _colloquialTamil(String value) {
    return value.split('/').last.trim();
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

    final responseMs =
        DateTime.now().difference(_questionStartTime).inMilliseconds;
    setState(() {
      selectedAnswer = answer;
      showResult = true;

      final currentWord = shuffledWords[currentIndex];
      final correct = answer == currentWord.tamil;
      if (answer == currentWord.tamil) {
        score++;
        final wordIndex = widget.words.indexOf(currentWord);
        if (wordIndex != -1) {
          // ignore: discarded_futures
          _awardXpForWord(wordIndex);
        }
      } else {
        final wordIndex = widget.words.indexOf(currentWord);
        if (wordIndex != -1) {
          context.read<MistakeProvider>().addMistake(
                widget.lessonIndex,
                wordIndex,
              );
        }
      }
      AnalyticsService().logQuizAnswer(
        lessonIndex: widget.lessonIndex,
        quizType: 'mcq',
        correct: correct,
        responseTimeMs: responseMs,
      );
      _playAudio(currentWord);
    });
  }

  Future<void> _awardXpForWord(int wordIndex) async {
    if (_isTestEnvironment()) return;
    final xp = await XpTrackerService().awardDailyXpForItem(
      'word:${widget.lessonIndex}:$wordIndex',
    );
    if (xp == 0) return;

    final user = AuthService().currentUser;
    if (user == null) return;
    await SyncService().updateStreakAndXP(
      user.uid,
      xp,
      reason: 'item',
    );
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
        _questionStartTime = DateTime.now();
      });
    } else {
      _showFinalResults();
    }
  }

  // Note: Ensure _showFinalResults uses the passed lessonIndex correctly as you did before.
  void _showFinalResults() {
    final percentage = QuizScore.percent(score, shuffledWords.length);
    final durationSec =
        DateTime.now().difference(_quizStartTime).inSeconds;
    final passed = percentage >= 80;
    final streakEligible = percentage >= 50;

    AnalyticsService().logQuizComplete(
      lessonIndex: widget.lessonIndex,
      quizType: 'mcq',
      scorePercent: percentage,
      passed: passed,
      durationSec: durationSec,
    );
    AnalyticsService().logLessonComplete(
      lessonIndex: widget.lessonIndex,
      scorePercent: percentage,
      durationSec: durationSec,
      passed: passed,
    );

    if (!_isTestEnvironment()) {
      // ignore: discarded_futures
      _playFeedbackSound(passed);
    }

    if (percentage >= 80) {
      _confettiController.play();
    }
    // 1. YOUR LOCAL SAVE
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final wasCompleted = progress.isLessonCompleted(widget.lessonIndex);
    progress.saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    if (passed && !wasCompleted) {
      Provider.of<ReviewProvider>(context, listen: false)
        .addLessonProgress(widget.words.length);
    }
    // 2. ADD THE CLOUD SYNC HERE (streak for 50%+)
    final user = AuthService().currentUser;
    if (user != null && streakEligible) {
      SyncService()
          .updateStreakAndXP(
            user.uid,
            passed ? XpRules.lessonPass : 0,
            reason: 'lesson',
          )
          .then((result) {
        if (!mounted) return;
        if (result.earnedFreeze) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Streak freeze earned!')),
          );
        } else if (result.consumedFreeze) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Streak freeze used to keep your streak.')),
          );
        }
      });
    }
    // Create review cards for this lesson (if not already created)
    Provider.of<ReviewProvider>(context, listen: false)
        .createCardsForLesson(widget.lessonIndex, widget.words.length);

    // (Your existing dialog code here)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PeacockMascot(
                    message: percentage >= 80
                        ? 'Quiz complete! Great job!'
                        : 'Good attempt! Try again.',
                    state: percentage >= 80
                        ? MascotState.celebrate
                        : MascotState.confused,
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: Text(
                      'You scored $score out of ${shuffledWords.length}',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 80 ? Colors.green : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                    if (widget.onComplete != null) {
                      widget.onComplete!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Finish'),
                ),
              ]),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playFeedbackSound(bool passed) async {
    if (_audioPlayer == null) return;
    final asset = passed
        ? 'assets/audio/success.mp3'
        : 'assets/audio/fail.mp3';
    try {
      final cleanPath = asset.replaceFirst('assets/', '');
      await _audioPlayer!.stop();
      await _audioPlayer!.play(AssetSource(cleanPath));
    } catch (_) {
      AnalyticsService().logAudioPlaybackError(
        source: 'mcq_feedback',
        lessonIndex: widget.lessonIndex,
      );
    }
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
    if (shuffledWords.isEmpty) {
      return const Center(child: Text('No words.'));
    }
    final currentWord = shuffledWords[currentIndex];

    // FIX: Wrap in LayoutBuilder and SingleChildScrollView
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: Column(
                              children: [
                                if (currentWord.imagePath != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child: SizedBox(
                                      height: 150,
                                      width: double.infinity,
                                      child: Image.asset(
                                        currentWord.imagePath!,
                                        key: const ValueKey('mcq-word-image'),
                                        fit: BoxFit.contain,
                                        semanticLabel: currentWord.hindi,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                          'Choose the correct Tamil translation:',
                                          style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 10),
                                      Text(
                                        currentWord.hindi,
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.blue),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),

                    const SizedBox(height: 20), // Added spacer

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
                                // FIX: Use minHeight 80 instead of height 80
                                constraints:
                                    const BoxConstraints(minHeight: 80),
                                decoration: BoxDecoration(
                                  color: !showResult
                                      ? Colors.white
                                      : (isCorrect
                                          ? Colors.green.shade50
                                          : (isSelected
                                              ? Colors.red.shade50
                                              : Colors.white)),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: !showResult
                                        ? Colors.grey.shade300
                                        : (isCorrect
                                            ? Colors.green
                                            : (isSelected
                                                ? Colors.red
                                                : Colors.grey.shade300)),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      pair.tamil,
                                      textAlign: TextAlign
                                          .center, // Center text for wrapping
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: showResult && !isCorrect
                                              ? Colors.grey
                                              : Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '(${pair.pronunciation})',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            ));
                      }).toList(),
                    ),

                    const SizedBox(height: 16), // Added spacer

                    if (showResult)
                      FilledButton(
                          onPressed: _nextQuestion,
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(18)),
                          child: const Text('Continue',
                              style: TextStyle(fontSize: 20)))
                    else
                      const SizedBox(height: 50),
                  ])),
        ),
      );
    });
  }
}
