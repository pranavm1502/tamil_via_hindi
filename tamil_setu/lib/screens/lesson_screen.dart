import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/word_pair.dart';
import '../services/tts_service.dart';
import 'quiz_view.dart';
import 'multiple_choice_quiz.dart';

/// Screen showing a single lesson with Learn and Quiz tabs.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final int lessonIndex;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.lessonIndex,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TtsService _ttsService = TtsService();
  bool _ttsAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initTts();
  }

  Future<void> _initTts() async {
    final available = await _ttsService.initialize();
    if (mounted) {
      setState(() {
        _ttsAvailable = available;
      });

      if (!available) {
        _showTtsWarning();
      }
    }
  }

  void _showTtsWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Text-to-Speech is not available on this device. Audio features will be disabled.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _speak(String text) async {
    final success = await _ttsService.speak(text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play audio.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Learn'),
            Tab(icon: Icon(Icons.quiz), text: 'Flashcards'),
            Tab(icon: Icon(Icons.check_box), text: 'MCQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLearnTab(),
          QuizView(
            words: widget.lesson.words,
            lessonIndex: widget.lessonIndex,
          ),
          MultipleChoiceQuiz(
            words: widget.lesson.words,
            lessonIndex: widget.lessonIndex,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.lesson.words.length,
      itemBuilder: (context, index) {
        final pair = widget.lesson.words[index];
        return _WordCard(
          pair: pair,
          onSpeak: _ttsAvailable ? () => _speak(pair.tamil) : null,
        );
      },
    );
  }
}

class _WordCard extends StatelessWidget {
  final WordPair pair;
  final VoidCallback? onSpeak;

  const _WordCard({
    required this.pair,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair.hindi,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pair.tamil,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    '(${pair.pronunciation})',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.volume_up,
                size: 30,
                color: onSpeak != null ? Colors.orange : Colors.grey,
              ),
              onPressed: onSpeak,
              tooltip: onSpeak != null ? 'Play audio' : 'Audio not available',
            ),
          ],
        ),
      ),
    );
  }
}
