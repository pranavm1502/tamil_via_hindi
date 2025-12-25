class WordPair {
  final String hindi;
  final String tamil;
  final String hindiScript; // The pronunciation bridge (e.g., वणक्कम)
  final String audioPath;   // e.g., assets/audio/l1_greet.wav

  WordPair({
    required this.hindi,
    required this.tamil,
    required this.hindiScript,
    required this.audioPath,
  });

  // Constructor to load from your generated JSON
  factory WordPair.fromJson(Map<String, dynamic> json) {
    return WordPair(
      hindi: json['hindi_meaning'],
      tamil: json['tamil'],
      hindiScript: json['hindi_script'],
      audioPath: json['audio'],
    );
  }
}