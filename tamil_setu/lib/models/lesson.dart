import 'word_pair.dart';

class Lesson {
  final int level;
  final String title;
  final String description;
  final List<WordPair> words;

  Lesson({
    required this.level,
    required this.title,
    required this.description,
    required this.words,
  });

  // Factory constructor to parse the JSON object
  factory Lesson.fromJson(Map<String, dynamic> json) {
    var list = json['words'] as List;
    List<WordPair> wordList = list.map((i) => WordPair.fromJson(i)).toList();

    return Lesson(
      level: json['level'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      words: wordList,
    );
  }
}
