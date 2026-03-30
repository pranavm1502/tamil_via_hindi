class WordPair {
  final String hindi;
  final String tamil;
  final String pronunciation; // The Hindi-script bridge
  final String audioPath; // e.g. "assets/audio/l1_namaste.mp3"
  final String? imagePath; // e.g. "assets/images/words/namaste.png"; null when absent

  WordPair({
    required this.hindi,
    required this.tamil,
    required this.pronunciation,
    required this.audioPath,
    this.imagePath,
  });

  // Factory constructor to parse the JSON object
  factory WordPair.fromJson(Map<String, dynamic> json) {
    return WordPair(
      hindi: json['hindi'] ?? '',
      tamil: json['tamil'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      // Default to empty if missing to prevent crashes
      audioPath: json['audio_path'] ?? '',
      imagePath: json['image_path'] as String?,
    );
  }
}
