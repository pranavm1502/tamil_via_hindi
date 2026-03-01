import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

/// Displays ranked learners by XP from Firestore.
class LeaderboardScreen extends StatelessWidget {
  final FirebaseFirestore? firestore;
  const LeaderboardScreen({super.key, this.firestore});

  @override
  Widget build(BuildContext context) {
    final resolvedFirestore = firestore ?? FirebaseFirestore.instance;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'All Time'),
            ],
          ),
        ),
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
            TabBarView(
              children: [
                _LeaderboardList(
                  firestore: resolvedFirestore,
                  orderField: 'xp_weekly',
                  xpLabel: 'Weekly XP',
                ),
                _LeaderboardList(
                  firestore: resolvedFirestore,
                  orderField: 'total_xp',
                  xpLabel: 'XP',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String orderField;
  final String xpLabel;

  static const List<String> _tagAdjectives = [
    'Kesar',
    'Neela',
    'Sundar',
    'Tez',
    'Veer',
    'Rani',
    'Raja',
    'Chand',
    'Suraj',
    'Ambar',
    'Mehek',
    'Sitar',
    'Rang',
    'Shakti',
    'Sagar',
    'Komal',
  ];

  static const List<String> _tagNouns = [
    'Mor',
    'Koyal',
    'Diya',
    'Baansuri',
    'Dhol',
    'Raga',
    'Kamal',
    'Genda',
    'Chakra',
    'Ghat',
    'Haat',
    'Bazaar',
    'Panghat',
    'Mehfil',
    'Rangoli',
    'Sitar',
  ];

  const _LeaderboardList({
    required this.firestore,
    required this.orderField,
    required this.xpLabel,
  });

  String _buildTag(String id) {
    final hash = _hashString(id);
    final adj = _tagAdjectives[hash % _tagAdjectives.length];
    final noun = _tagNouns[(hash ~/ 7) % _tagNouns.length];
    final number = (hash % 90) + 10;
    return '$adj $noun-$number';
  }

  int _hashString(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('users')
          .orderBy(orderField, descending: true)
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
            final doc = docs[index - 1];
            final data = doc.data() as Map<String, dynamic>;
            final displayName =
                (data['display_tag'] as String?) ?? _buildTag(doc.id);
            final xp = data[orderField] ?? 0;
            final streak = data['streak_count'] ?? 0;
            final bool isTopThree = rank <= 3;
            final IconData? trophyIcon = switch (rank) {
              1 => Icons.emoji_events,
              2 => Icons.emoji_events,
              3 => Icons.emoji_events,
              _ => null,
            };
            final Color? trophyColor = switch (rank) {
              1 => const Color(0xFFD4AF37),
              2 => const Color(0xFFC0C0C0),
              3 => const Color(0xFFCD7F32),
              _ => null,
            };
            return Semantics(
              label:
                  'Rank $rank, $displayName, $xp $xpLabel, streak $streak days',
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
                  subtitle: Text('$xpLabel: $xp  |  Streak: $streak'),
                    trailing: trophyIcon == null
                      ? null
                      : Icon(trophyIcon, color: trophyColor),
                ),
              ),
            );
          },
        );
      },
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
