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
      final cleanPath = path.replaceFirst('assets/', '');
      await _audioPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
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
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOP HALF: HINDI (The Question)
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  pair.hindi,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              
              // BOTTOM HALF: TAMIL + PRONUNCIATION (The Answer)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tamil Script and Hindi Transliteration combined
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          pair.tamil,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '(${pair.pronunciation})',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              
              // AUDIO BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: IconButton(
                    icon: const Icon(Icons.volume_up_rounded,
                        size: 36, color: Colors.blue),
                    onPressed: () => _playAudio(pair.audioPath),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}