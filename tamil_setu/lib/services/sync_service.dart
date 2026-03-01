import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';

class StreakUpdateResult {
  final bool earnedFreeze;
  final bool consumedFreeze;
  final int streakCount;
  final int freezeCount;

  const StreakUpdateResult({
    required this.earnedFreeze,
    required this.consumedFreeze,
    required this.streakCount,
    required this.freezeCount,
  });
}

/// Reads and writes user stats to Firestore, with optional test injection.
class SyncService {
  final FirebaseFirestore _db;

  SyncService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Stream the user stats document, defaulting to an empty map if missing.
  Stream<Map<String, dynamic>> userStatsStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.data() ?? <String, dynamic>{},
        );
  }

  /// Update XP and streak based on last activity, creating a user on first sync.
  Future<StreakUpdateResult> updateStreakAndXP(
    String uid,
    int xpGained, {
    String? displayName,
    String? reason,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var earnedFreeze = false;
    var consumedFreeze = false;
    var resultStreak = 1;
    var resultFreezes = 0;

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        // New user initialization
        transaction.set(userRef, {
          'total_xp': xpGained,
          'streak_count': 1,
          'last_activity': Timestamp.fromDate(today),
          'streak_freezes': 2,
          'last_freeze_date': null,
          'last_freeze_award_streak': 0,
          'last_lesson_freeze_date': null,
          'display_name':
              (displayName == null || displayName.isEmpty)
                  ? 'Learner'
                  : displayName,
        });
        resultStreak = 1;
        resultFreezes = 2;
        return;
      }

      final data = snapshot.data()!;
      int currentXP = data['total_xp'] ?? 0;
      int currentStreak = data['streak_count'] ?? 0;
      int currentFreezes = data['streak_freezes'] ?? 0;
      DateTime lastActivity = (data['last_activity'] as Timestamp).toDate();
      DateTime? lastFreezeDate =
          (data['last_freeze_date'] as Timestamp?)?.toDate();
      int lastFreezeAwardStreak = data['last_freeze_award_streak'] ?? 0;
      DateTime? lastLessonFreezeDate =
          (data['last_lesson_freeze_date'] as Timestamp?)?.toDate();

      // Streak Logic
      int newStreak = currentStreak;
      if (today.difference(lastActivity).inDays == 1) {
        newStreak++; // Next day!
        if (newStreak == 3 && lastFreezeAwardStreak != 3) {
          currentFreezes += 1;
          lastFreezeAwardStreak = 3;
          earnedFreeze = true;
        }
      } else if (today.difference(lastActivity).inDays > 1) {
        final usedFreezeToday = lastFreezeDate != null &&
            lastFreezeDate.year == today.year &&
            lastFreezeDate.month == today.month &&
            lastFreezeDate.day == today.day;
        if (currentFreezes > 0 && !usedFreezeToday) {
          currentFreezes -= 1;
          lastFreezeDate = today;
          consumedFreeze = true;
        } else {
          newStreak = 1; // Streak broken
          lastFreezeAwardStreak = 0;
        }
      }

      if (currentFreezes > 4) {
        currentFreezes = 4;
      }

      final updateData = <String, dynamic>{
        'total_xp': currentXP + xpGained,
        'streak_count': newStreak,
        'last_activity': Timestamp.fromDate(today),
        'streak_freezes': currentFreezes,
        'last_freeze_date':
            lastFreezeDate == null ? null : Timestamp.fromDate(lastFreezeDate),
        'last_freeze_award_streak': lastFreezeAwardStreak,
        'last_lesson_freeze_date': lastLessonFreezeDate == null
          ? null
          : Timestamp.fromDate(lastLessonFreezeDate),
      };

      if (displayName != null && displayName.isNotEmpty) {
        final existingName = data['display_name'] as String?;
        if (existingName == null || existingName != displayName) {
          updateData['display_name'] = displayName;
        }
      }

        transaction.update(userRef, updateData);
        resultStreak = newStreak;
        resultFreezes = currentFreezes;
      });
    } catch (e) {
      AnalyticsService().logSyncError(action: 'update_streak_xp');
      rethrow;
    }

    if (reason != null && reason.isNotEmpty) {
      AnalyticsService().logStreakUpdated(
        streakDays: resultStreak,
        reason: reason,
      );
    }

    return StreakUpdateResult(
      earnedFreeze: earnedFreeze,
      consumedFreeze: consumedFreeze,
      streakCount: resultStreak,
      freezeCount: resultFreezes,
    );
  }

  /// Update display name without touching streak or XP.
  Future<void> upsertDisplayName(String uid, String displayName) async {
    if (displayName.isEmpty) return;
    await _db.collection('users').doc(uid).set(
      {'display_name': displayName},
      SetOptions(merge: true),
    );
  }

  /// Award one streak freeze per week for passing the build lesson.
  Future<bool> awardWeeklyLessonFreeze(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var awarded = false;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? <String, dynamic>{};
      final currentFreezes = (data['streak_freezes'] ?? 0) as int;
      final lastLessonFreezeDate =
          (data['last_lesson_freeze_date'] as Timestamp?)?.toDate();
      final daysSinceLast = lastLessonFreezeDate == null
          ? 999
          : today.difference(lastLessonFreezeDate).inDays;

      if (daysSinceLast < 7 || currentFreezes >= 4) {
        return;
      }

      final nextFreezes = currentFreezes + 1;
      transaction.update(userRef, {
        'streak_freezes': nextFreezes > 4 ? 4 : nextFreezes,
        'last_lesson_freeze_date': Timestamp.fromDate(today),
      });
      awarded = true;
    });

    return awarded;
  }
}
