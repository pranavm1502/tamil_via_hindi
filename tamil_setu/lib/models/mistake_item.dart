class MistakeItem {
  final int lessonIndex;
  final int wordIndex;
  final int count;
  final DateTime lastSeen;

  MistakeItem({
    required this.lessonIndex,
    required this.wordIndex,
    required this.count,
    required this.lastSeen,
  });

  String get id => 'lesson${lessonIndex}_word$wordIndex';

  Map<String, dynamic> toJson() {
    return {
      'lessonIndex': lessonIndex,
      'wordIndex': wordIndex,
      'count': count,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory MistakeItem.fromJson(Map<String, dynamic> json) {
    return MistakeItem(
      lessonIndex: json['lessonIndex'] as int,
      wordIndex: json['wordIndex'] as int,
      count: json['count'] as int? ?? 1,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }

  MistakeItem copyWith({int? count, DateTime? lastSeen}) {
    return MistakeItem(
      lessonIndex: lessonIndex,
      wordIndex: wordIndex,
      count: count ?? this.count,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
