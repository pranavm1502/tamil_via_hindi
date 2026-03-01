import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // 1. Added Import
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

class QuizView extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;
  final VoidCallback? onComplete;

  const QuizView({
    super.key,
    required this.words,
    required this.lessonIndex,
    this.onComplete,
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
  late ConfettiController _confettiController; // 2. Added Controller
  late DateTime _quizStartTime;
  late DateTime _questionStartTime;

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
    // 3. Initialize Controller
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _quizStartTime = DateTime.now();
    _questionStartTime = _quizStartTime;
    AnalyticsService().logQuizStart(
      lessonIndex: widget.lessonIndex,
      quizType: 'flashcard',
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose(); // 4. Dispose Controller
    super.dispose();
  }

  void _playAudio(WordPair pair) async {
    try {
      final colloquial = _colloquialTamil(pair.tamil);
      if (pair.tamil.contains('/') && colloquial.isNotEmpty) {
        final spoke = await TtsService().speak(
          colloquial,
          source: 'flashcard',
          lessonIndex: widget.lessonIndex,
        );
        if (spoke) return;
      }

      if (pair.audioPath.isEmpty) return;
      final cleanPath = pair.audioPath.replaceFirst('assets/', '');
      await _audioPlayer.setPlaybackRate(1.20); // Faster rate
      await _audioPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
      AnalyticsService().logAudioPlaybackError(
        source: 'flashcard',
        lessonIndex: widget.lessonIndex,
      );
    }
  }

  String _colloquialTamil(String value) {
    return value.split('/').last.trim();
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

  void _nextCard(bool knewIt) {
    final responseMs =
        DateTime.now().difference(_questionStartTime).inMilliseconds;
    AnalyticsService().logQuizAnswer(
      lessonIndex: widget.lessonIndex,
      quizType: 'flashcard',
      correct: knewIt,
      responseTimeMs: responseMs,
    );
    if (knewIt) {
      score++;
    } else {
      final wordIndex = widget.words.indexOf(shuffledWords[currentIndex]);
      if (wordIndex != -1) {
        context.read<MistakeProvider>().addMistake(
              widget.lessonIndex,
              wordIndex,
            );
      }
    }
    setState(() {
      if (currentIndex < shuffledWords.length - 1) {
        currentIndex++;
        showAnswer = false;
        _questionStartTime = DateTime.now();
      } else {
        _showResultDialog();
      }
    });
  }

  void _showFreezeToast(BuildContext context, StreakUpdateResult result) {
    if (result.earnedFreeze) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Streak freeze earned!')),
      );
    } else if (result.consumedFreeze) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Streak freeze used to keep your streak.')),
      );
    }
  }

  Future<void> _showResultDialog() async {
    // 1. Calculate percentage (Fixes 'unused variable' warning)
    final percentage = (score / shuffledWords.length * 100).round();
    final durationSec =
        DateTime.now().difference(_quizStartTime).inSeconds;
    final passed = percentage >= 80;

    AnalyticsService().logQuizComplete(
      lessonIndex: widget.lessonIndex,
      quizType: 'flashcard',
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

    // 5. Trigger Confetti for high scores
    if (percentage >= 80) {
      _confettiController.play();
    }

    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final wasCompleted = progress.isLessonCompleted(widget.lessonIndex);
    progress.saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    if (passed && !wasCompleted) {
      Provider.of<ReviewProvider>(context, listen: false)
        .addLessonProgress(widget.words.length);
    }

    // 2. ADD THE CLOUD SYNC HERE
    final user = AuthService().currentUser;
    if (user != null && percentage >= 80) {
      final result = await SyncService().updateStreakAndXP(
        user.uid,
        XpRules.lessonPass,
        displayName: user.displayName ?? user.email,
        reason: 'lesson',
      );
      if (!mounted) return;
      _showFreezeToast(context, result);
    }
    // Create review cards for this lesson (if not already created)
    Provider.of<ReviewProvider>(context, listen: false)
      .createCardsForLesson(widget.lessonIndex, widget.words.length);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        // 6. Wrap in Stack to overlay confetti
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
                      ? 'Excellent! Great job!'
                      : 'Keep practicing! You are getting better.',
                  state: percentage >= 80
                      ? MascotState.celebrate
                      : MascotState.confused,
                ),
                const SizedBox(height: 24),
                Text(
                  'You scored $score out of ${shuffledWords.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: percentage >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop(); // Stop animation on exit
                  Navigator.pop(ctx);
                  _restartQuiz();
                },
                child: const Text('Retry Quiz'),
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
            ],
          ),
          // 7. Added the Confetti Widget
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
                value: (currentIndex + 1) / shuffledWords.length,
                minHeight: 10,
                color: Colors.green.shade600),
            const SizedBox(height: 20),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(minHeight: 240),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Translate this Hindi word:',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(currentWord.hindi,
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    const Divider(height: 40),
                    if (showAnswer)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(currentWord.tamil,
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange)),
                          const SizedBox(height: 4),
                          Text('(${currentWord.pronunciation})',
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          IconButton(
                              icon: const Icon(Icons.volume_up,
                                  color: Colors.blue),
                                onPressed: () => _playAudio(currentWord)),
                        ],
                      )
                    else
                      const Text('?',
                          style: TextStyle(fontSize: 50, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (!showAnswer)
              FilledButton(
                  onPressed: () {
                    setState(() => showAnswer = true);
                    _playAudio(currentWord);
                  },
                  child: const Text('Show Answer'))
            else
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => _nextCard(false),
                        child: const Text('Practice'))),
                const SizedBox(width: 16),
                Expanded(
                    child: FilledButton(
                        onPressed: () => _nextCard(true),
                        child: const Text('I knew it!'))),
              ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
