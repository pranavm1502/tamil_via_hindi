class SentenceItem {
  final String hindi;
  final String tamil;
  final String pronunciation;
  final String audioPath;
  final List<String> tags;

  const SentenceItem({
    required this.hindi,
    required this.tamil,
    required this.pronunciation,
    required this.audioPath,
    required this.tags,
  });

  factory SentenceItem.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? [];
    return SentenceItem(
      hindi: json['hindi'] ?? '',
      tamil: json['tamil'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      audioPath: json['audio_path'] ?? '',
      tags: rawTags.map((tag) => tag.toString()).toList(),
    );
  }
}
