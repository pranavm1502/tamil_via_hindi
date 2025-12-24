import 'word_pair.dart';

/// Represents a lesson in the curriculum.
///
/// Each lesson contains a [title], [description], and a list of [words]
/// to learn.
class Lesson {
  final String title;
  final String description;
  final List<WordPair> words;

  Lesson({
    required this.title,
    required this.description,
    required this.words,
  });
}
