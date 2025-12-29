import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/review_provider.dart';
import '../providers/content_provider.dart';
import '../services/srs_service.dart';
import '../widgets/peacock_mascot.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _showAnswer = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

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

  void _handleReview(BuildContext context, ReviewQuality quality) async {
    final reviewProvider = context.read<ReviewProvider>();
    await reviewProvider.reviewCurrentCard(quality);

    setState(() {
      _showAnswer = false;
    });

    // If no more cards, show completion dialog
    if (!reviewProvider.hasMoreCards) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final reviewProvider = context.read<ReviewProvider>();
    final cardsReviewed = reviewProvider.totalCardsInSession;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PeacockMascot(
              message: 'Review Complete! बहुत अच्छा!',
              state: MascotState.celebrate,
            ),
            const SizedBox(height: 24),
            Text(
              'You reviewed $cardsReviewed card${cardsReviewed != 1 ? 's' : ''}!',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (reviewProvider.currentStreak > 0)
              Text(
                '🔥 ${reviewProvider.currentStreak} day streak!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<ReviewProvider, ContentProvider>(
        builder: (context, reviewProvider, contentProvider, child) {
          if (!reviewProvider.hasMoreCards) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PeacockMascot(
                    message: 'No cards to review!',
                    state: MascotState.guide,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Come back later for more reviews.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            );
          }

          final currentCard = reviewProvider.currentCard!;
          final progress = (reviewProvider.currentCardIndex + 1) /
              reviewProvider.totalCardsInSession;

          // Get the actual word pair from the lesson
          final lesson = contentProvider.lessons[currentCard.lessonIndex];
          final wordPair = lesson.words[currentCard.wordIndex];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Card ${reviewProvider.currentCardIndex + 1} / ${reviewProvider.totalCardsInSession}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green,
                ),
                const SizedBox(height: 32),

                // Flashcard
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_showAnswer) {
                        setState(() => _showAnswer = true);
                        _playAudio(wordPair.audioPath);
                      }
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Question side
                            const Text(
                              'Translate to Tamil:',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              wordPair.hindi,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const Divider(height: 48),

                            // Answer side
                            if (_showAnswer) ...[
                              Column(
                                children: [
                                  Text(
                                    wordPair.tamil,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '(${wordPair.pronunciation})',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.blueGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.volume_up,
                                      size: 36,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _playAudio(wordPair.audioPath),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Icon(
                                Icons.touch_app,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap to reveal',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Rating buttons (only show when answer is revealed)
                if (_showAnswer) ...[
                  const Text(
                    'How well did you remember?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RatingButton(
                          label: 'Again',
                          color: Colors.red,
                          interval: '10m',
                          onPressed: () => _handleReview(context, ReviewQuality.again),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RatingButton(
                          label: 'Hard',
                          color: Colors.orange,
                          interval: _getIntervalText(
                            reviewProvider.predictNextReview(
                              currentCard,
                              ReviewQuality.hard,
                            ),
                          ),
                          onPressed: () => _handleReview(context, ReviewQuality.hard),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RatingButton(
                          label: 'Good',
                          color: Colors.green,
                          interval: _getIntervalText(
                            reviewProvider.predictNextReview(
                              currentCard,
                              ReviewQuality.good,
                            ),
                          ),
                          onPressed: () => _handleReview(context, ReviewQuality.good),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RatingButton(
                          label: 'Easy',
                          color: Colors.blue,
                          interval: _getIntervalText(
                            reviewProvider.predictNextReview(
                              currentCard,
                              ReviewQuality.easy,
                            ),
                          ),
                          onPressed: () => _handleReview(context, ReviewQuality.easy),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () {
                      setState(() => _showAnswer = true);
                      _playAudio(wordPair.audioPath);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                    ),
                    child: const Text(
                      'Show Answer',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _getIntervalText(DateTime nextReview) {
    final now = DateTime.now();
    final difference = nextReview.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final String interval;
  final VoidCallback onPressed;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.interval,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            interval,
            style: TextStyle(
              color: color.withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
