import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lesson.dart';
import '../models/word_pair.dart';
import 'quiz_view.dart';
import 'multiple_choice_quiz.dart';
import 'sentence_builder_quiz.dart';
import '../providers/sentence_provider.dart';
import '../services/tts_service.dart';
import '../services/analytics_service.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final int lessonIndex;
  final String source;

  const LessonScreen(
      {super.key,
      required this.lesson,
      required this.lessonIndex,
      this.source = 'dashboard'});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Initialize as nullable to allow conditional setup
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 2. Safe Initialization: Only create player if NOT in a test
    if (!_isTestEnvironment()) {
      _audioPlayer = AudioPlayer();
    }

    AnalyticsService().logLessonStart(
      lessonIndex: widget.lessonIndex,
      lessonTitle: widget.lesson.title,
      source: widget.source,
    );
  }

  // Helper to detect test environment consistently
  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<void> _playAudio(WordPair pair) async {
    // 3. Early return if player wasn't initialized (e.g., during tests)
    if (_audioPlayer == null) {
      debugPrint('Audio playback skipped: Test environment detected.');
      return;
    }

    try {
      final colloquial = _colloquialTamil(pair.tamil);
      if (pair.tamil.contains('/') && colloquial.isNotEmpty) {
        final spoke = await TtsService().speak(
          colloquial,
          source: 'lesson_learn',
          lessonIndex: widget.lessonIndex,
        );
        if (spoke) return;
      }

      if (pair.audioPath.isEmpty) return;
      final cleanPath = pair.audioPath.replaceFirst('assets/', '');
      await _audioPlayer!.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Audio Error: $e');
      AnalyticsService().logAudioPlaybackError(
        source: 'lesson_learn',
        lessonIndex: widget.lessonIndex,
      );
    }
  }

  String _colloquialTamil(String value) {
    return value.split('/').last.trim();
  }

  @override
  void dispose() {
    // 4. Null-safe disposal
    _audioPlayer?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentences = context
        .watch<SentenceProvider>()
        .sentencesForLesson(
          lessonIndex: widget.lessonIndex,
          lessonTitle: widget.lesson.title,
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
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
            Tab(icon: Icon(Icons.view_quilt), text: 'Build'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLearnTab(),
          QuizView(words: widget.lesson.words, lessonIndex: widget.lessonIndex),
          MultipleChoiceQuiz(
              words: widget.lesson.words, lessonIndex: widget.lessonIndex),
          SentenceBuilderQuiz(
            sentences: sentences,
            lessonIndex: widget.lessonIndex,
          ),
        ],
      ),
    );
  }

// (Inside _buildLearnTab method)
  Widget _buildLearnTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.lesson.words.length,
      itemBuilder: (context, index) {
        final pair = widget.lesson.words[index];
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  pair.hindi,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  // FIX: Switch to Row to put button on the right
                  children: [
                    Expanded(
                      // FIX: Wrap text in Expanded so it wraps instead of overflowing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            pair.tamil,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(${pair.pronunciation})',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded,
                          size: 36, color: Colors.blue),
                      onPressed: () => _playAudio(pair),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
