import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/checkpoint.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';
import '../providers/content_provider.dart';
import '../providers/mistake_provider.dart';
import '../widgets/peacock_mascot.dart';
import '../services/tts_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/xp_rules.dart';
import '../services/analytics_service.dart';
import '../services/xp_tracker_service.dart';

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
  AudioPlayer? _audioPlayer;
  late ConfettiController _confettiController;
  late DateTime _quizStartTime;
  late DateTime _questionStartTime;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (!_isTestEnvironment()) {
      _audioPlayer = AudioPlayer();
    }
    _loadWordsFromLessons();
    _generateOptions();

    _quizStartTime = DateTime.now();
    _questionStartTime = _quizStartTime;
    AnalyticsService().logQuizStart(
      lessonIndex: widget.checkpoint.startLessonIndex,
      quizType: 'checkpoint',
    );
  }

  void _loadWordsFromLessons() {
    final contentProvider = context.read<ContentProvider>();
    allWords = [];

    // Collect all words from the checkpoint's lesson range
    for (int i = widget.checkpoint.startLessonIndex;
        i <= widget.checkpoint.endLessonIndex;
        i++) {
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
    _audioPlayer?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _playAudio(WordPair pair) async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer!.stop();
      await TtsService().stop();
      final colloquial = _colloquialTamil(pair.tamil);
      if (pair.tamil.contains('/') && colloquial.isNotEmpty) {
        final spoke = await TtsService().speak(
          colloquial,
          source: 'checkpoint',
          lessonIndex: widget.checkpoint.startLessonIndex,
        );
        if (spoke) return;
      }

      if (pair.audioPath.isEmpty) return;
      final cleanPath = pair.audioPath.replaceFirst('assets/', '');
      await _audioPlayer!.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
      AnalyticsService().logAudioPlaybackError(
        source: 'checkpoint',
        lessonIndex: widget.checkpoint.startLessonIndex,
      );
    }
  }

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  String _colloquialTamil(String value) {
    return value.split('/').last.trim();
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

    final responseMs =
        DateTime.now().difference(_questionStartTime).inMilliseconds;
    setState(() {
      selectedAnswer = answer;
      showResult = true;

      final currentWord = quizWords[currentIndex];
      final correct = answer == currentWord.tamil;
      if (answer == currentWord.tamil) {
        score++;
        // ignore: discarded_futures
        _awardXpForWord(currentWord);
      } else {
        _recordMistake(currentWord);
      }
      AnalyticsService().logQuizAnswer(
        lessonIndex: widget.checkpoint.startLessonIndex,
        quizType: 'checkpoint',
        correct: correct,
        responseTimeMs: responseMs,
      );
      _playAudio(currentWord);
    });
  }

  void _recordMistake(WordPair pair) {
    final content = context.read<ContentProvider>();
    for (int i = 0; i < content.lessons.length; i++) {
      final lesson = content.lessons[i];
      final index = lesson.words.indexWhere((word) {
        return word.hindi == pair.hindi && word.tamil == pair.tamil;
      });
      if (index != -1) {
        context.read<MistakeProvider>().addMistake(i, index);
        return;
      }
    }
  }

  Future<void> _awardXpForWord(WordPair pair) async {
    if (_isTestEnvironment()) return;
    final indices = _findLessonWordIndex(pair);
    if (indices == null) return;

    final xp = await XpTrackerService().awardDailyXpForItem(
      'word:${indices.lessonIndex}:${indices.wordIndex}',
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

  _LessonWordIndex? _findLessonWordIndex(WordPair pair) {
    final content = context.read<ContentProvider>();
    for (int i = 0; i < content.lessons.length; i++) {
      final lesson = content.lessons[i];
      final index = lesson.words.indexWhere((word) {
        return word.hindi == pair.hindi && word.tamil == pair.tamil;
      });
      if (index != -1) {
        return _LessonWordIndex(i, index);
      }
    }
    return null;
  }

  void _nextQuestion() {
    if (currentIndex < quizWords.length - 1) {
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

  void _showFinalResults() {
    final percentage = (score / quizWords.length * 100).round();
    final durationSec =
        DateTime.now().difference(_quizStartTime).inSeconds;
    final passed = percentage >= 80;
    final streakEligible = percentage >= 50;

    AnalyticsService().logQuizComplete(
      lessonIndex: widget.checkpoint.startLessonIndex,
      quizType: 'checkpoint',
      scorePercent: percentage,
      passed: passed,
      durationSec: durationSec,
    );

    if (!_isTestEnvironment()) {
      // ignore: discarded_futures
      _playFeedbackSound(passed);
    }

    if (percentage >= 80) {
      _confettiController.play();
    }

    Provider.of<ProgressProvider>(context, listen: false).saveCheckpointScore(
        widget.checkpoint.checkpointNumber, score, quizWords.length);

    final user = AuthService().currentUser;
    if (user != null && streakEligible) {
      SyncService()
          .updateStreakAndXP(
            user.uid,
            passed ? XpRules.checkpointPass : 0,
            reason: 'checkpoint',
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PeacockMascot(
                  message: percentage >= 80
                      ? 'Checkpoint Passed! 🎉'
                      : 'Keep practicing! You are close.',
                  state: percentage >= 80
                      ? MascotState.celebrate
                      : MascotState.confused,
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
        source: 'checkpoint_feedback',
        lessonIndex: widget.checkpoint.startLessonIndex,
      );
    }
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
        body: const Center(
            child: Text('No words available for this checkpoint.')),
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
                            Expanded(
                              child: Text(
                                'Question ${currentIndex + 1} / ${quizWords.length}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.checkpoint.lessonRange,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
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

                    const SizedBox(
                        height: 20), // Spacer between card and options

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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                                children: [
                                  Text(
                                    pair.tamil,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: showResult && !isCorrect
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                    // Removed hard constraints here to allow natural wrapping
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
                              style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.all(18)),
                              child: const Text('Continue',
                                  style: TextStyle(fontSize: 20)),
                            )
                          : const SizedBox(
                              height:
                                  60), // Maintain space even when button hidden
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

class _LessonWordIndex {
  final int lessonIndex;
  final int wordIndex;

  const _LessonWordIndex(this.lessonIndex, this.wordIndex);
}
