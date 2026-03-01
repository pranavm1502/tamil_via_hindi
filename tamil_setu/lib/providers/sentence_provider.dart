import 'package:flutter/material.dart';
import '../models/sentence_item.dart';
import '../data/sentences.dart';

class SentenceProvider with ChangeNotifier {
  List<SentenceItem> _sentences = [];
  bool _isLoading = true;

  List<SentenceItem> get sentences => _sentences;
  bool get isLoading => _isLoading;

  Future<void> loadSentences() async {
    _isLoading = true;
    notifyListeners();

    _sentences = await loadSentenceData();

    _isLoading = false;
    notifyListeners();
  }

  List<SentenceItem> sentencesForLesson({
    required int lessonIndex,
    required String lessonTitle,
  }) {
    if (_sentences.isEmpty) return [];

    final normalizedTitle = _normalizeTag(lessonTitle);
    final lessonTag = 'lesson:$lessonIndex';
    final topicTag = 'topic:$normalizedTitle';

    final filtered = _sentences.where((item) {
      return item.tags.contains(lessonTag) || item.tags.contains(topicTag);
    }).toList();

    return filtered.isNotEmpty ? filtered : _sentences;
  }

  String _normalizeTag(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
