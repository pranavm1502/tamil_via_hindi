import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateStreakAndXP(String uid, int xpGained) async {
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
          'display_name': 'Learner', 
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

      transaction.update(userRef, {
        'total_xp': currentXP + xpGained,
        'streak_count': newStreak,
        'last_activity': Timestamp.fromDate(today),
      });
    });
  }
}