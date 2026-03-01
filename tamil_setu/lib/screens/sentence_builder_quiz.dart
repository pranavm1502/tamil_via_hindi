import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sentence_item.dart';
import '../services/tts_service.dart';

class SentenceBuilderQuiz extends StatefulWidget {
  final List<SentenceItem> sentences;
  final int lessonIndex;

  const SentenceBuilderQuiz({
    super.key,
    required this.sentences,
    required this.lessonIndex,
  });

  @override
  State<SentenceBuilderQuiz> createState() => _SentenceBuilderQuizState();
}

class _SentenceBuilderQuizState extends State<SentenceBuilderQuiz> {
  AudioPlayer? _audioPlayer;
  late List<SentenceItem> _shuffledSentences;
  int _currentIndex = 0;
  List<String> _availableTokens = [];
  List<String> _selectedTokens = [];
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    if (!_isTestEnvironment()) {
      _audioPlayer = AudioPlayer();
    }
    _shuffledSentences = List.from(widget.sentences)..shuffle();
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
  }

  String _colloquialTamil(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains('/')) return trimmed;
    return trimmed.split('/').last.trim();
  }

  void _selectToken(String token) {
    if (_showResult) return;
    setState(() {
      _availableTokens.remove(token);
      _selectedTokens.add(token);
    });
  }

  void _unselectToken(String token) {
    if (_showResult) return;
    setState(() {
      _selectedTokens.remove(token);
      _availableTokens.add(token);
    });
  }

  Future<void> _playAudio(SentenceItem sentence) async {
    if (_audioPlayer == null) return;
    final colloquial = _colloquialTamil(sentence.tamil);
    if (colloquial.isEmpty) return;
    if (sentence.audioPath.isNotEmpty) {
      final cleanPath = sentence.audioPath.replaceFirst('assets/', '');
      await _audioPlayer!.stop();
      await _audioPlayer!.play(AssetSource(cleanPath));
      return;
    }
    await TtsService().speak(colloquial);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final current = _shuffledSentences[_currentIndex];
    final target = _colloquialTamil(current.tamil);
    final attempt = _selectedTokens.join(' ');
    final correct = attempt == target;

    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });
  }

  void _next() {
    if (_currentIndex < _shuffledSentences.length - 1) {
      setState(() {
        _currentIndex++;
        _prepareTokens();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sentence builder complete!')),
      );
    }
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTokens
                  .map(
                    (token) => ActionChip(
                      label: Text(token),
                      onPressed: () => _unselectToken(token),
                    ),
                  )
                  .toList(),
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
