import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review_card.dart';
import '../providers/mistake_provider.dart';
import '../providers/content_provider.dart';
import '../models/word_pair.dart';
import '../services/tts_service.dart';

class MistakesReviewScreen extends StatefulWidget {
  /// When provided, drills exactly these cards (in-session mistakes mode).
  /// The persistent [MistakeProvider] is not consulted in this case.
  final List<ReviewCard>? sessionCards;

  const MistakesReviewScreen({super.key, this.sessionCards});

  @override
  State<MistakesReviewScreen> createState() => _MistakesReviewScreenState();
}

class _MistakesReviewScreenState extends State<MistakesReviewScreen> {
  bool _showAnswer = false;

  // State for session-cards mode (in-memory, no MistakeProvider)
  late final List<ReviewCard> _sessionList;
  int _sessionIndex = 0;
  bool get _isSessionMode => widget.sessionCards != null;

  @override
  void initState() {
    super.initState();
    if (_isSessionMode) {
      _sessionList = List.of(widget.sessionCards!);
    } else {
      _sessionList = [];
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<MistakeProvider>();
        await provider.loadMistakes();
        provider.startSession();
      });
    }
  }

  Future<void> _playAudio(WordPair pair) async {
    final colloquial = pair.tamil.contains('/')
        ? pair.tamil.split('/').last.trim()
        : pair.tamil;
    if (colloquial.isNotEmpty) {
      final spoke = await TtsService().speak(colloquial);
      if (spoke) return;
    }
  }

  void _nextCard({required bool resolved}) async {
    if (_isSessionMode) {
      if (!mounted) return;
      setState(() {
        _sessionIndex++;
        _showAnswer = false;
      });
      return;
    }
    final provider = context.read<MistakeProvider>();
    if (resolved) {
      await provider.resolveCurrent();
    } else {
      provider.skipCurrent();
    }
    if (!mounted) return;
    setState(() {
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mistakes Review')),
      body: _isSessionMode ? _buildSessionBody() : _buildPersistentBody(),
    );
  }

  Widget _buildSessionBody() {
    final content = context.watch<ContentProvider>();
    final total = _sessionList.length;

    if (total == 0 || _sessionIndex >= total) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 56),
              const SizedBox(height: 12),
              const Text('Drill complete! Great work.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final current = _sessionList[_sessionIndex];
    if (current.lessonIndex >= content.lessons.length) {
      return const Center(child: Text('Lesson data unavailable.'));
    }
    final lesson = content.lessons[current.lessonIndex];
    if (current.wordIndex >= lesson.words.length) {
      return const Center(child: Text('Word data unavailable.'));
    }
    final word = lesson.words[current.wordIndex];
    final progress = (_sessionIndex + 1) / total;

    return _buildCardBody(
      word: word,
      progress: progress,
      currentIndex: _sessionIndex,
      total: total,
    );
  }

  Widget _buildPersistentBody() {
    return Consumer2<MistakeProvider, ContentProvider>(
      builder: (context, mistakes, content, child) {
        if (mistakes.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!mistakes.hasMore) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 56),
                  const SizedBox(height: 12),
                  const Text('No mistakes to review right now.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        final current = mistakes.currentMistake!;
        if (current.lessonIndex >= content.lessons.length) {
          return const Center(child: Text('Lesson data unavailable.'));
        }
        final lesson = content.lessons[current.lessonIndex];
        if (current.wordIndex >= lesson.words.length) {
          return const Center(child: Text('Word data unavailable.'));
        }
        final word = lesson.words[current.wordIndex];
        final progress = (mistakes.currentIndex + 1) /
            (mistakes.totalInSession == 0 ? 1 : mistakes.totalInSession);

        return _buildCardBody(
          word: word,
          progress: progress,
          currentIndex: mistakes.currentIndex,
          total: mistakes.totalInSession,
        );
      },
    );
  }

  Widget _buildCardBody({
    required WordPair word,
    required double progress,
    required int currentIndex,
    required int total,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Card ${currentIndex + 1} / $total',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Translate to Tamil',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      word.hindi,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 32),
                    if (_showAnswer) ...[
                      Text(
                        word.tamil,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '(${word.pronunciation})',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => _playAudio(word),
                        icon: const Icon(Icons.volume_up),
                      ),
                    ] else
                      const Text(
                        '?',
                        style: TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_showAnswer)
              FilledButton(
                onPressed: () => setState(() => _showAnswer = true),
                child: const Text('Show Answer'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _nextCard(resolved: false),
                      child: const Text('Still Hard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _nextCard(resolved: true),
                      child: const Text('Got It'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
