import 'package:flutter_tts/flutter_tts.dart';

/// Service for managing Text-to-Speech functionality.
///
/// This is a singleton service that handles TTS initialization,
/// configuration, and playback with proper error handling.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isAvailable = true;

  TtsService._internal();

  /// Initialize the TTS service with Tamil language support.
  ///
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    try {
      await _flutterTts.setLanguage('ta-IN');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setPitch(1.0);

      // Test if TTS is actually available
      final languages = await _flutterTts.getLanguages;
      _isAvailable = languages != null && languages.isNotEmpty;
      _isInitialized = true;

      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  /// Speak the given text in Tamil.
  ///
  /// Returns true if speech was initiated successfully, false otherwise.
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      return false;
    }

    try {
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Check if TTS is available on this device.
  bool get isAvailable => _isAvailable;

  /// Dispose of TTS resources.
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}
