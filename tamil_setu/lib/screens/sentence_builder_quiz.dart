import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../models/sentence_item.dart';
import '../providers/progress_provider.dart';
import '../providers/review_provider.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';
import '../services/analytics_service.dart';
import '../services/sync_service.dart';
import '../services/xp_rules.dart';
import '../services/quiz_score.dart';
import '../services/xp_tracker_service.dart';
import '../widgets/peacock_mascot.dart';

class SentenceBuilderQuiz extends StatefulWidget {
  final List<SentenceItem> sentences;
  final int lessonIndex;
  final VoidCallback? onComplete;

  const SentenceBuilderQuiz({
    super.key,
    required this.sentences,
    required this.lessonIndex,
    this.onComplete,
  });

  @override
  State<SentenceBuilderQuiz> createState() => _SentenceBuilderQuizState();
}

class _SentenceBuilderQuizState extends State<SentenceBuilderQuiz> {
  AudioPlayer? _audioPlayer;
  late ConfettiController _confettiController;
  late List<SentenceItem> _shuffledSentences;
  int _currentIndex = 0;
  List<String> _availableTokens = [];
  List<String> _selectedTokens = [];
  bool _showResult = false;
  bool _isCorrect = false;
  int _correctCount = 0;
  late DateTime _quizStartTime;
  late DateTime _questionStartTime;

  @override
  void initState() {
    super.initState();
    if (!_isTestEnvironment()) {
      _audioPlayer = AudioPlayer();
    }
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _shuffledSentences = List.from(widget.sentences)..shuffle();
    _quizStartTime = DateTime.now();
    _questionStartTime = _quizStartTime;
    _correctCount = 0;
    AnalyticsService().logQuizStart(
      lessonIndex: widget.lessonIndex,
      quizType: 'build',
    );
    _prepareTokens();
  }

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  void _prepareTokens() {
    final current = _shuffledSentences[_currentIndex];
    final tamil = _colloquialTamil(current.tamil);
    final tokens = tamil.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    _availableTokens = tokens.toList()..shuffle();
    _selectedTokens = [];
    _showResult = false;
    _isCorrect = false;
    _questionStartTime = DateTime.now();
  }

  String _colloquialTamil(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains('/')) return trimmed;
    return trimmed.split('/').last.trim();
  }

  void _selectToken(String token) {
    if (_showResult) return;
    if (!_isTestEnvironment()) {
      // ignore: discarded_futures
      _playTokenAudio(token);
    }
    setState(() {
      _availableTokens.remove(token);
      _selectedTokens.add(token);
    });
  }

  void _unselectToken(String token) {
    if (_showResult) return;
    if (!_isTestEnvironment()) {
      // ignore: discarded_futures
      _playTokenAudio(token);
    }
    setState(() {
      _selectedTokens.remove(token);
      _availableTokens.add(token);
    });
  }

  void _reorderSelectedTokens(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      final token = _selectedTokens.removeAt(fromIndex);
      final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
      _selectedTokens.insert(insertIndex, token);
    });
  }

  Widget _buildSelectedToken(int index) {
    final token = _selectedTokens[index];
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !_showResult,
      onAcceptWithDetails: (details) =>
          _reorderSelectedTokens(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: ActionChip(
              label: Text(token),
              onPressed: null,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: ActionChip(
              label: Text(token),
              onPressed: () => _unselectToken(token),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: highlight
                  ? Border.all(color: Colors.blueAccent, width: 1.5)
                  : null,
            ),
            child: ActionChip(
              label: Text(token),
              onPressed: () => _unselectToken(token),
            ),
          ),
        );
      },
    );
  }

  Future<void> _playTokenAudio(String token) async {
    final cleaned = token.trim();
    if (cleaned.isEmpty) return;
    await TtsService().speak(
      cleaned,
      source: 'build_token',
      lessonIndex: widget.lessonIndex,
    );
  }

  Future<void> _playAudio(SentenceItem sentence) async {
    if (_audioPlayer == null) return;
    final colloquial = _colloquialTamil(sentence.tamil);
    if (colloquial.isEmpty) return;
    try {
      if (sentence.audioPath.isNotEmpty) {
        final cleanPath = sentence.audioPath.replaceFirst('assets/', '');
        await _audioPlayer!.stop();
        await _audioPlayer!.play(AssetSource(cleanPath));
        return;
      }
      await TtsService().speak(
        colloquial,
        source: 'build',
        lessonIndex: widget.lessonIndex,
      );
    } catch (e) {
      debugPrint('Audio Error: $e');
      AnalyticsService().logAudioPlaybackError(
        source: 'build',
        lessonIndex: widget.lessonIndex,
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkAnswer() async {
    final current = _shuffledSentences[_currentIndex];
    final target = _colloquialTamil(current.tamil);
    final attempt = _selectedTokens.join(' ');
    final correct = attempt == target;
    final responseMs =
        DateTime.now().difference(_questionStartTime).inMilliseconds;

    if (target.isNotEmpty && !_isTestEnvironment()) {
      try {
        await _audioPlayer?.stop();
        await TtsService().speak(
          target,
          source: 'build_check',
          lessonIndex: widget.lessonIndex,
        );
      } catch (_) {
        // Ignore TTS errors so feedback still plays.
      }
    }

    if (!_isTestEnvironment()) {
      await _playFeedbackSound(correct);
    }

    if (correct) {
      // ignore: discarded_futures
      _awardXpForSentence();
    }

    AnalyticsService().logQuizAnswer(
      lessonIndex: widget.lessonIndex,
      quizType: 'build',
      correct: correct,
      responseTimeMs: responseMs,
    );

    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _correctCount++;
      }
    });
  }

  Future<void> _awardXpForSentence() async {
    if (_isTestEnvironment()) return;
    final sentenceIndex = widget.sentences.indexOf(
      _shuffledSentences[_currentIndex],
    );
    if (sentenceIndex == -1) return;

    final xp = await XpTrackerService().awardDailyXpForItem(
      'sentence:${widget.lessonIndex}:$sentenceIndex',
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

  Future<void> _playFeedbackSound(bool correct) async {
    if (_audioPlayer == null) return;
    final asset = correct
        ? 'assets/audio/success.mp3'
        : 'assets/audio/fail.mp3';
    try {
      final cleanPath = asset.replaceFirst('assets/', '');
      await _audioPlayer!.stop();
      await _audioPlayer!.play(AssetSource(cleanPath));
    } catch (_) {
      AnalyticsService().logAudioPlaybackError(
        source: 'build_feedback',
        lessonIndex: widget.lessonIndex,
      );
    }
  }

  Future<void> _next() async {
    if (_currentIndex < _shuffledSentences.length - 1) {
      setState(() {
        _currentIndex++;
        _prepareTokens();
      });
    } else {
      final durationSec =
          DateTime.now().difference(_quizStartTime).inSeconds;
      final scorePercent =
          QuizScore.percent(_correctCount, _shuffledSentences.length);
      final passed = scorePercent >= 80;
      final streakEligible = scorePercent >= 50;
      AnalyticsService().logQuizComplete(
        lessonIndex: widget.lessonIndex,
        quizType: 'build',
        scorePercent: scorePercent,
        passed: passed,
        durationSec: durationSec,
      );
      if (passed) {
        await _awardBuildXp();
      }
      if (streakEligible) {
        await _updateLessonStreak(passed: passed);
      }
      if (passed) {
        await _awardWeeklyLessonFreeze();
      }
      _showCompletionDialog(scorePercent, passed);
    }
  }

  Future<void> _updateLessonStreak({required bool passed}) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await SyncService().updateStreakAndXP(
      user.uid,
      passed ? XpRules.lessonPass : 0,
      reason: 'lesson',
    );
  }

  Future<void> _awardBuildXp() async {
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final awarded = await progress.markBuildCompleted(widget.lessonIndex);
    if (!awarded) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    await SyncService().updateStreakAndXP(
      user.uid,
      XpRules.buildPass,
      reason: 'build',
    );
  }

  Future<void> _awardWeeklyLessonFreeze() async {
    final awarded = await Provider.of<ReviewProvider>(context, listen: false)
        .awardWeeklyLessonFreeze();

    if (awarded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly streak freeze earned!')),
      );
    }

    final user = AuthService().currentUser;
    if (user == null) return;
    await SyncService().awardWeeklyLessonFreeze(user.uid);
  }

  void _showCompletionDialog(int scorePercent, bool passed) {
    if (!mounted) return;

    final message = passed
      ? 'Fantastic work! Lesson unlocked.'
      : 'Almost there! Try again.';

    if (passed) {
      _confettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SizedBox(
              width: 320, // Increase dialog width to prevent awkward wrapping
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PeacockMascot(
                    message: message,
                    state: passed ? MascotState.celebrate : MascotState.confused,
                    layout: MascotLayout.overlap,
                    imageSize: 88,
                    overlapInset: 84,
                    imageOffset: const Offset(16, 0),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: Text(
                      'You scored $_correctCount out of ${_shuffledSentences.length}.',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      '$scorePercent%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.pop(ctx);
                  setState(() {
                    _currentIndex = 0;
                    _correctCount = 0;
                    _shuffledSentences.shuffle();
                    _prepareTokens();
                  });
                },
                child: const Text('Retry'),
              ),
              FilledButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.pop(ctx);
                  widget.onComplete?.call();
                },
                child: const Text('Finish'),
              ),
            ],
          ),
          if (passed)
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


  @override
  Widget build(BuildContext context) {
    if (_shuffledSentences.isEmpty) {
      return const Center(child: Text('No sentences available yet.'));
    }

    final current = _shuffledSentences[_currentIndex];
    final target = _colloquialTamil(current.tamil);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Arrange the Tamil words',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              current.hindi,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Long-press to rearrange words',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: _selectedTokens.isEmpty
                  ? Text(
                      'Tap words below to build the sentence.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedTokens
                          .asMap()
                          .entries
                          .map((entry) => _buildSelectedToken(entry.key))
                          .toList()
                        ..add(
                          DragTarget<int>(
                            onWillAcceptWithDetails: (_) => !_showResult,
                            onAcceptWithDetails: (details) =>
                                _reorderSelectedTokens(
                              details.data,
                              _selectedTokens.length,
                            ),
                            builder: (context, candidateData, rejectedData) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 24,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: candidateData.isNotEmpty
                                      ? Border.all(
                                          color: Colors.blueAccent,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTokens
                  .map(
                    (token) => OutlinedButton(
                      onPressed: () => _selectToken(token),
                      child: Text(token),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _playAudio(current),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedTokens.isEmpty || _showResult
                        ? null
                        : _checkAnswer,
                    child: const Text('Check'),
                  ),
                ),
              ],
            ),
            if (_showResult) ...[
              const SizedBox(height: 12),
              Text(
                _isCorrect ? 'Correct!' : 'Not quite. Correct answer:',
                style: TextStyle(
                  color: _isCorrect ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                target,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _next,
                child: const Text('Next'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
