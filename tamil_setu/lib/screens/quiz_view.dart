import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // 1. Added Import
import '../models/word_pair.dart';
import '../providers/progress_provider.dart';
import '../widgets/peacock_mascot.dart';

class QuizView extends StatefulWidget {
  final List<WordPair> words;
  final int lessonIndex;

  const QuizView({super.key, required this.words, required this.lessonIndex});

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

  @override
  void initState() {
    super.initState();
    shuffledWords = List.from(widget.words)..shuffle();
    // 3. Initialize Controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose(); // 4. Dispose Controller
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

  void _restartQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      showAnswer = false;
      shuffledWords.shuffle();
    });
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

  void _showResultDialog() {
    final percentage = (score / shuffledWords.length * 100).round();
    
    // 5. Trigger Confetti for high scores
    if (percentage >= 80) {
      _confettiController.play();
    }

    Provider.of<ProgressProvider>(context, listen: false)
        .saveQuizScore(widget.lessonIndex, score, shuffledWords.length);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack( // 6. Wrap in Stack to overlay confetti
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PeacockMascot(
                  message: percentage >= 80 
                      ? 'Excellent! बहुत अच्छा!' 
                      : 'Keep practicing! अभ्यास करते रहो!',
                  state: percentage >= 80 ? MascotState.celebrate : MascotState.confused,
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
                  Navigator.pop(context); 
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / shuffledWords.length, 
            minHeight: 10, 
            color: Colors.green.shade600
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Translate this Hindi word:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    currentWord.hindi, 
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue)
                  ),
                  const Divider(height: 40),
                  if (showAnswer)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentWord.tamil,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${currentWord.pronunciation})',
                          style: const TextStyle(fontSize: 20, color: Colors.blueGrey)
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.blue),
                          onPressed: () => _playAudio(currentWord.audioPath)
                        ),
                      ],
                    )
                  else
                    const Text('?', style: TextStyle(fontSize: 50, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!showAnswer)
            FilledButton(
              onPressed: () { 
                setState(() => showAnswer = true); 
                _playAudio(currentWord.audioPath); 
              }, 
              child: const Text('Show Answer')
            )
          else
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _nextCard(false), 
                  child: const Text('Practice')
                )
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => _nextCard(true), 
                  child: const Text('I knew it!')
                )
              ),
            ]),
        ],
      ),
    );
  }
}