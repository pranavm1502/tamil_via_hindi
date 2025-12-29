/// Represents a single flashcard for spaced repetition review.
/// Uses the SM-2 (SuperMemo 2) algorithm for optimal scheduling.
class ReviewCard {
  /// Unique identifier: "lesson{X}_word{Y}"
  final String id;

  /// Index of the lesson this word belongs to
  final int lessonIndex;

  /// Index of the word within the lesson
  final int wordIndex;

  /// When this card should be reviewed next
  DateTime nextReview;

  /// Number of consecutive correct reviews (resets to 0 on failure)
  int repetitions;

  /// SM-2 easiness factor (starts at 2.5, range: 1.3 to 2.5+)
  /// Higher = easier word, longer intervals between reviews
  double easiness;

  /// Current interval in days until next review
  int intervalDays;

  /// Last time this card was reviewed (null if never reviewed)
  DateTime? lastReviewed;

  /// Total number of times this card has been reviewed
  int totalReviews;

  /// Total number of correct answers
  int totalCorrect;

  /// When this card was created (for analytics)
  final DateTime createdAt;

  ReviewCard({
    required this.id,
    required this.lessonIndex,
    required this.wordIndex,
    required this.nextReview,
    this.repetitions = 0,
    this.easiness = 2.5,
    this.intervalDays = 1,
    this.lastReviewed,
    this.totalReviews = 0,
    this.totalCorrect = 0,
    required this.createdAt,
  });

  /// Create a new review card for a word pair (initial state)
  factory ReviewCard.newCard({
    required int lessonIndex,
    required int wordIndex,
  }) {
    final now = DateTime.now();
    return ReviewCard(
      id: 'lesson${lessonIndex}_word$wordIndex',
      lessonIndex: lessonIndex,
      wordIndex: wordIndex,
      nextReview: now, // Available for review immediately
      createdAt: now,
    );
  }

  /// Check if this card is due for review
  bool get isDue => DateTime.now().isAfter(nextReview) ||
                    DateTime.now().isAtSameMomentAs(nextReview);

  /// Calculate accuracy percentage
  double get accuracy => totalReviews == 0 ? 0.0 : (totalCorrect / totalReviews) * 100;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonIndex': lessonIndex,
      'wordIndex': wordIndex,
      'nextReview': nextReview.toIso8601String(),
      'repetitions': repetitions,
      'easiness': easiness,
      'intervalDays': intervalDays,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      id: json['id'] as String,
      lessonIndex: json['lessonIndex'] as int,
      wordIndex: json['wordIndex'] as int,
      nextReview: DateTime.parse(json['nextReview'] as String),
      repetitions: json['repetitions'] as int? ?? 0,
      easiness: (json['easiness'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] as int? ?? 1,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  ReviewCard copyWith({
    String? id,
    int? lessonIndex,
    int? wordIndex,
    DateTime? nextReview,
    int? repetitions,
    double? easiness,
    int? intervalDays,
    DateTime? lastReviewed,
    int? totalReviews,
    int? totalCorrect,
    DateTime? createdAt,
  }) {
    return ReviewCard(
      id: id ?? this.id,
      lessonIndex: lessonIndex ?? this.lessonIndex,
      wordIndex: wordIndex ?? this.wordIndex,
      nextReview: nextReview ?? this.nextReview,
      repetitions: repetitions ?? this.repetitions,
      easiness: easiness ?? this.easiness,
      intervalDays: intervalDays ?? this.intervalDays,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      totalReviews: totalReviews ?? this.totalReviews,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ReviewCard(id: $id, due: ${isDue ? "YES" : "NO"}, next: $nextReview, reps: $repetitions, ease: ${easiness.toStringAsFixed(2)})';
  }
}
