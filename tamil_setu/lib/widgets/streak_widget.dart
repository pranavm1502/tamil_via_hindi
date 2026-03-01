import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';


/// Shows the signed-in user's streak with a subtle animated card.
class StreakWidget extends StatelessWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final int? streakOverride;
  final int? freezesOverride;
  const StreakWidget({
    super.key,
    this.auth,
    this.firestore,
    this.streakOverride,
    this.freezesOverride,
  });

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  Widget build(BuildContext context) {
    if (_isTestEnvironment() && auth == null) {
      return const SizedBox.shrink();
    }

    if (streakOverride != null || freezesOverride != null) {
      final streak = streakOverride ?? 0;
      final freezes = freezesOverride ?? 0;
      return _buildCard(context, streak, freezes);
    }

    final resolvedAuth = auth ?? FirebaseAuth.instance;
    final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
    final user = resolvedAuth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: resolvedFirestore
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final streak = data?['streak_count'] ?? 0;
        final freezes = data?['streak_freezes'] ?? 0;
        return _buildCard(context, streak, freezes);
      },
    );
  }

  Widget _buildCard(BuildContext context, int streak, int freezes) {
    final card = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  PeacockTheme.peacockBlue.withAlpha(24),
                  PeacockTheme.peacockGreen.withAlpha(28),
                ],
              ),
              border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(60)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: PeacockTheme.vibrantOrange, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Streak',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text('$streak days'),
                        backgroundColor:
                            PeacockTheme.peacockGreen.withAlpha(60),
                      ),
                      Chip(
                        label: Text('Freezes: $freezes'),
                        backgroundColor:
                            PeacockTheme.peacockBlue.withAlpha(50),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Semantics(
      container: true,
      label: 'Streak: $streak days',
      child: _isTestEnvironment()
          ? card
          : ZoomIn(
              duration: const Duration(milliseconds: 800),
              child: card,
            ),
    );
  }
}
