import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

/// Displays ranked learners by XP from Firestore.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PeacockTheme.softCream,
                    PeacockTheme.softCream.withAlpha(230),
                    PeacockTheme.peacockGreen.withAlpha(18),
                  ],
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('total_xp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No leaderboard data.'));
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: docs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _LeaderboardHeader(count: docs.length);
                  }
                  final rank = index;
                  final data = docs[index - 1].data() as Map<String, dynamic>;
                  final displayName = data['display_name'] ?? 'Learner';
                  final xp = data['total_xp'] ?? 0;
                  final streak = data['streak_count'] ?? 0;
                  final bool isTopThree = rank <= 3;
                  return Semantics(
                    label:
                        'Rank $rank, $displayName, $xp XP, streak $streak days',
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isTopThree ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isTopThree
                              ? PeacockTheme.peacockBlue.withAlpha(120)
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTopThree
                              ? PeacockTheme.peacockBlue.withAlpha(60)
                              : PeacockTheme.peacockGreen.withAlpha(40),
                          child: Text('$rank'),
                        ),
                        title: Text(displayName),
                        subtitle: Text('XP: $xp  |  Streak: $streak'),
                        trailing: isTopThree
                            ? const Icon(Icons.emoji_events,
                                color: PeacockTheme.vibrantOrange)
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Decorative header summarizing the leaderboard count.
class _LeaderboardHeader extends StatelessWidget {
  final int count;
  const _LeaderboardHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            PeacockTheme.peacockBlue.withAlpha(28),
            PeacockTheme.peacockGreen.withAlpha(26),
          ],
        ),
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.leaderboard, color: PeacockTheme.peacockBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Learners',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$count learners ranked',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
