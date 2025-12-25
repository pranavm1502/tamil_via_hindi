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
      debugPrint("Audio Error: $e");
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
    // ... (Result logic logic remains the same, omitted for brevity but include it in your file)
    // NOTE: Keep your existing _showResultDialog logic here
    
    // Just saving score for context:
    Provider.of<ProgressProvider>(context, listen: false)
        .saveQuizScore(widget.lessonIndex, score, shuffledWords.length);
        
    // (Paste your existing showDialog code here)
  }

  @override
  Widget build(BuildContext context) {
    if (shuffledWords.isEmpty) return const Center(child: Text('No words available.'));

    final currentWord = shuffledWords[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / shuffledWords.length,
            backgroundColor: Colors.grey[300],
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          Text('Question ${currentIndex + 1}/${shuffledWords.length}', textAlign: TextAlign.center),
          const SizedBox(height: 20),

          Card(
            elevation: 8,
            child: Container(
              height: 250, // Slightly taller to fit everything
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Translate this Hindi word:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    currentWord.hindi,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),
                  if (showAnswer) ...[
                    Text(
                      currentWord.tamil,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    Text(
                      currentWord.pronunciation,
                      style: const TextStyle(fontSize: 20, color: Colors.blueGrey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 30, color: Colors.blue),
                      onPressed: () => _playAudio(currentWord.audioPath),
                    ),
                  ] else
                    const Text('?', style: TextStyle(fontSize: 40, color: Colors.orange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          if (!showAnswer)
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () {
                setState(() => showAnswer = true);
                _playAudio(currentWord.audioPath); // Auto-play when revealed
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show Answer', style: TextStyle(fontSize: 18)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Wrong'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Correct'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}