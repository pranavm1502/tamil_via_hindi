import 'dart:io';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  String? _sessionId;
  String? _appVersion;
  bool _initialized = false;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<void> initialize({bool coldStart = true}) async {
    if (_initialized || _isTestEnvironment()) return;

    final info = await PackageInfo.fromPlatform();
    _appVersion = info.version;
    _sessionId = _generateSessionId();
    _initialized = true;

    await logAppOpen(coldStart: coldStart);
  }

  void bindUserStream(Stream<User?> userStream) {
    if (_isTestEnvironment()) return;
    userStream.listen((user) {
      _analytics.setUserId(id: user?.uid);
    });
  }

  Future<void> setUserId(String? userId) async {
    if (_isTestEnvironment()) return;
    await _analytics.setUserId(id: userId);
  }

  Future<void> logAppOpen({required bool coldStart}) async {
    await logEvent('app_open', {
      'cold_start': coldStart,
    });
  }

  Future<void> logDashboardView({
    required int lessonsVisible,
    int? streakDays,
    int? xpTotal,
  }) async {
    await logEvent('dashboard_view', {
      'lessons_visible': lessonsVisible,
      if (streakDays != null) 'streak_days': streakDays,
      if (xpTotal != null) 'xp_total': xpTotal,
    });
  }

  Future<void> logLessonStart({
    required int lessonIndex,
    required String lessonTitle,
    required String source,
  }) async {
    await logEvent('lesson_start', {
      'lesson_index': lessonIndex,
      'lesson_title': lessonTitle,
      'source': source,
    });
  }

  Future<void> logLessonComplete({
    required int lessonIndex,
    required int scorePercent,
    required int durationSec,
    required bool passed,
  }) async {
    await logEvent('lesson_complete', {
      'lesson_index': lessonIndex,
      'score_percent': scorePercent,
      'duration_sec': durationSec,
      'passed': passed,
    });
  }

  Future<void> logQuizStart({
    required int lessonIndex,
    required String quizType,
  }) async {
    await logEvent('quiz_start', {
      'lesson_index': lessonIndex,
      'quiz_type': quizType,
    });
  }

  Future<void> logQuizAnswer({
    required int lessonIndex,
    required String quizType,
    required bool correct,
    required int responseTimeMs,
  }) async {
    await logEvent('quiz_answer', {
      'lesson_index': lessonIndex,
      'quiz_type': quizType,
      'correct': correct,
      'response_time_ms': responseTimeMs,
    });
  }

  Future<void> logQuizComplete({
    required int lessonIndex,
    required String quizType,
    required int scorePercent,
    required bool passed,
    required int durationSec,
  }) async {
    await logEvent('quiz_complete', {
      'lesson_index': lessonIndex,
      'quiz_type': quizType,
      'score_percent': scorePercent,
      'passed': passed,
      'duration_sec': durationSec,
    });
  }

  Future<void> logReviewStart({
    required int dueCards,
    required int dailyGoal,
  }) async {
    await logEvent('review_start', {
      'due_cards': dueCards,
      'daily_goal': dailyGoal,
    });
  }

  Future<void> logReviewAnswer({
    required int lessonIndex,
    required int wordIndex,
    required String quality,
  }) async {
    await logEvent('review_answer', {
      'lesson_index': lessonIndex,
      'word_index': wordIndex,
      'quality': quality,
    });
  }

  Future<void> logReviewComplete({
    required int cardsReviewed,
    required int durationSec,
    required int streakDays,
  }) async {
    await logEvent('review_complete', {
      'cards_reviewed': cardsReviewed,
      'duration_sec': durationSec,
      'streak_days': streakDays,
    });
  }

  Future<void> logStreakUpdated({
    required int streakDays,
    required String reason,
  }) async {
    await logEvent('streak_updated', {
      'streak_days': streakDays,
      'reason': reason,
    });
  }

  Future<void> logNotificationScheduled({
    required String timeLocal,
  }) async {
    await logEvent('notification_scheduled', {
      'time_local': timeLocal,
    });
  }

  Future<void> logAudioPlaybackError({
    required String source,
    int? lessonIndex,
  }) async {
    await logEvent('audio_playback_error', {
      'source': source,
      if (lessonIndex != null) 'lesson_index': lessonIndex,
    });
  }

  Future<void> logTtsError({
    required String source,
    int? lessonIndex,
  }) async {
    await logEvent('tts_error', {
      'source': source,
      if (lessonIndex != null) 'lesson_index': lessonIndex,
    });
  }

  Future<void> logSyncError({
    required String action,
  }) async {
    await logEvent('sync_error', {
      'action': action,
    });
  }

  Future<void> logEvent(String name, Map<String, Object?> params) async {
    if (_isTestEnvironment()) return;

    final enriched = <String, Object?>{
      ..._baseParams(),
      ...params,
    };
    final cleaned = _compactParams(enriched);

    try {
      await _analytics.logEvent(name: name, parameters: cleaned);
    } catch (_) {
      // Ignore analytics failures to avoid user impact.
    }
  }

  Map<String, Object?> _baseParams() {
    return {
      if (_sessionId != null) 'session_id': _sessionId,
      if (_appVersion != null) 'app_version': _appVersion,
      'device_platform': _platformString(),
    };
  }

  Map<String, Object> _compactParams(Map<String, Object?> params) {
    final cleaned = <String, Object>{};
    params.forEach((key, value) {
      if (value != null) {
        cleaned[key] = value;
      }
    });
    return cleaned;
  }

  String _platformString() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _generateSessionId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(8, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${DateTime.now().millisecondsSinceEpoch}-$hex';
  }
}
