import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lesson.dart';
import 'quiz_view.dart';
import 'multiple_choice_quiz.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _playAudio(String path) async {
    try {
      // AssetSource automatically adds 'assets/', so we remove it from your stored path
      // stored path: "assets/audio/file.mp3" -> needed: "audio/file.mp3"
      final cleanPath = path.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
            Tab(icon: Icon(Icons.menu_book), text: 'Learn'),
            Tab(icon: Icon(Icons.flash_on), text: 'Flashcards'),
            Tab(icon: Icon(Icons.quiz), text: 'MCQ'),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              pair.tamil,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  pair.hindi,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                // Show the pronunciation bridge (e.g., "वणक्कम")
                Text(
                  "(${pair.pronunciation})",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up_rounded,
                  size: 32, color: Colors.blue),
              onPressed: () => _playAudio(pair.audioPath),
            ),
          ),
        );
      },
    );
  }
}
