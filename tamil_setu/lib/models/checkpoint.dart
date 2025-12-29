/// Represents a checkpoint quiz that appears after every N lessons.
///
/// Checkpoint quizzes test knowledge from multiple previous lessons
/// and must be passed to unlock the next section.
class Checkpoint {
  /// Checkpoint number (1, 2, 3...)
  final int checkpointNumber;

  /// Title of the checkpoint
  final String title;

  /// Description of what this checkpoint covers
  final String description;

  /// Starting lesson index (inclusive) - 0-based
  final int startLessonIndex;

  /// Ending lesson index (inclusive) - 0-based
  final int endLessonIndex;

  /// Number of questions in the checkpoint quiz
  final int questionCount;

  /// Minimum score percentage required to pass (default 80%)
  final int passingScore;

  Checkpoint({
    required this.checkpointNumber,
    required this.title,
    required this.description,
    required this.startLessonIndex,
    required this.endLessonIndex,
    this.questionCount = 15,
    this.passingScore = 80,
  });

  /// Get the lesson range as a readable string
  String get lessonRange => 'Lessons ${startLessonIndex + 1}-${endLessonIndex + 1}';

  /// Get number of lessons covered
  int get lessonCount => endLessonIndex - startLessonIndex + 1;
}

/// Service to generate checkpoints based on total lesson count
class CheckpointService {
  /// Number of lessons between checkpoints
  static const int lessonsPerSection = 5;

  /// Generate checkpoints for a given number of lessons
  static List<Checkpoint> generateCheckpoints(int totalLessons) {
    final List<Checkpoint> checkpoints = [];

    // Create a checkpoint after every 5 lessons
    for (int i = lessonsPerSection; i <= totalLessons; i += lessonsPerSection) {
      final checkpointNumber = (i / lessonsPerSection).floor();
      final startIndex = i - lessonsPerSection;
      final endIndex = i - 1;

      checkpoints.add(Checkpoint(
        checkpointNumber: checkpointNumber,
        title: 'Checkpoint $checkpointNumber',
        description: 'Review Quiz for ${_getCheckpointDescription(checkpointNumber)}',
        startLessonIndex: startIndex,
        endLessonIndex: endIndex,
      ));
    }

    return checkpoints;
  }

  /// Get a descriptive name for the checkpoint section
  static String _getCheckpointDescription(int checkpointNumber) {
    switch (checkpointNumber) {
      case 1:
        return 'Foundation Skills';
      case 2:
        return 'Intermediate Skills';
      case 3:
        return 'Advanced Skills';
      default:
        return 'Section $checkpointNumber';
    }
  }

  /// Check if a lesson index is immediately before a checkpoint
  static bool isCheckpointLesson(int lessonIndex) {
    // Checkpoints appear after lessons 4, 9, 14, etc. (0-indexed)
    return (lessonIndex + 1) % lessonsPerSection == 0;
  }

  /// Get the checkpoint index that follows a given lesson
  static int getCheckpointIndexForLesson(int lessonIndex) {
    return (lessonIndex + 1) ~/ lessonsPerSection - 1;
  }

  /// Check if a lesson is part of a section that requires checkpoint completion
  static bool requiresCheckpointCompletion(int lessonIndex, int checkpointNumber) {
    final sectionStart = checkpointNumber * lessonsPerSection;
    return lessonIndex >= sectionStart;
  }
}
