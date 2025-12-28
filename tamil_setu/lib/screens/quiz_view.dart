import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';

class QuizView extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;

  const QuizView({
    super.key,
    required this.words,
    required this.lessonIndex,
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

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
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

  void _nextCard(bool knewIt) {
    if (knewIt) score++;

    setState(() {
      if (currentIndex < shuffledWords.length - 1) {
        currentIndex++;
        showAnswer = false;
      } else {
        _showResultDialog();
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      showAnswer = false;
      shuffledWords.shuffle();
    });
  }

  void _showResultDialog() {
    final percentage = (score / shuffledWords.length * 100).round();

    String message;
    IconData icon;
    Color color;

    if (percentage >= 80) {
      message = 'Excellent! बहुत अच्छा!';
      icon = Icons.star;
      color = Colors.green;
    } else if (percentage >= 60) {
      message = 'Good job! अच्छा!';
      icon = Icons.thumb_up;
      color = Colors.orange;
    } else {
      message = 'Keep practicing! अभ्यास करते रहो!';
      icon = Icons.school;
      color = Colors.blue;
    }

    Provider.of<ProgressProvider>(context, listen: false)
        .saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You scored $score out of ${shuffledWords.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restartQuiz(); 
            },
            child: const Text('Retry Quiz'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); 
            },
            child: const Text('Finish'),
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 16),
          Text('Question ${currentIndex + 1}/${shuffledWords.length}',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          
          // Flashcard View
          Card(
            elevation: 10,
            shadowColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              height: 280,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Translate this Hindi word:',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 15),
                  Text(
                    currentWord.hindi,
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30, color: Colors.grey),
                  
                  // ANSWER / QUESTION MARK
                  if (showAnswer) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentWord.tamil,
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${currentWord.pronunciation})', 
                          style:
                              const TextStyle(fontSize: 30, color: Colors.blueGrey),
                        ),
                        // Audio Button
                        IconButton(
                          icon: const Icon(Icons.volume_up,
                              size: 35, color: Colors.blue),
                          onPressed: () => _playAudio(currentWord.audioPath),
                        ),
                      ],
                    ),
                  ] else
                    const Text('?',
                        style: TextStyle(fontSize: 50, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // ACTION BUTTONS
          if (!showAnswer)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() => showAnswer = true);
                _playAudio(currentWord.audioPath);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Answer', style: TextStyle(fontSize: 20)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _nextCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text('I need more practice', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _nextCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text('I knew it!', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}