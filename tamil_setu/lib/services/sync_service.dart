import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> updateStreakAndXP(
    String uid,
    int xpGained, {
    String? displayName,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        // New user initialization
        transaction.set(userRef, {
          'total_xp': xpGained,
          'streak_count': 1,
          'last_activity': Timestamp.fromDate(today),
          'display_name':
              (displayName == null || displayName.isEmpty)
                  ? 'Learner'
                  : displayName,
        });
        return;
      }

      final data = snapshot.data()!;
      int currentXP = data['total_xp'] ?? 0;
      int currentStreak = data['streak_count'] ?? 0;
      DateTime lastActivity = (data['last_activity'] as Timestamp).toDate();

      // Streak Logic
      int newStreak = currentStreak;
      if (today.difference(lastActivity).inDays == 1) {
        newStreak++; // Next day!
      } else if (today.difference(lastActivity).inDays > 1) {
        newStreak = 1; // Streak broken
      }

      final updateData = <String, dynamic>{
        'total_xp': currentXP + xpGained,
        'streak_count': newStreak,
        'last_activity': Timestamp.fromDate(today),
      };

      if (displayName != null && displayName.isNotEmpty) {
        final existingName = data['display_name'] as String?;
        if (existingName == null || existingName != displayName) {
          updateData['display_name'] = displayName;
        }
      }

      transaction.update(userRef, updateData);
    });
  }

  /// Update display name without touching streak or XP.
  Future<void> upsertDisplayName(String uid, String displayName) async {
    if (displayName.isEmpty) return;
    await _db.collection('users').doc(uid).set(
      {'display_name': displayName},
      SetOptions(merge: true),
    );
  }
}
