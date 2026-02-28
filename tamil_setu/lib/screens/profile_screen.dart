import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../providers/review_provider.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  final SyncService? syncService;
  const ProfileScreen({super.key, this.syncService});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final progress = context.watch<ProgressProvider>();
    final review = context.watch<ReviewProvider>();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 72),
                const SizedBox(height: 12),
                const Text('Sign in to view your stats'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.read<AuthService>().signInWithGoogle(),
                  child: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final reviewStats = review.statistics;
    final accuracy = (reviewStats['accuracy'] as double?) ?? 0.0;
    final statsService = syncService ?? SyncService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: statsService.userStatsStream(user.uid),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final displayName =
              (data?['display_name'] as String?) ?? user.displayName ?? 'Learner';
          final totalXp = (data?['total_xp'] as int?) ?? 0;
          final streak = (data?['streak_count'] as int?) ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ProfileHeader(
                name: displayName,
                email: user.email,
                photoUrl: user.photoURL,
              ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Learning Stats'),
              const SizedBox(height: 8),
              _StatsGrid(
                items: [
                  _StatItem(label: 'Total XP', value: '$totalXp'),
                  _StatItem(label: 'Streak', value: '$streak days'),
                  _StatItem(
                    label: 'Lessons Completed',
                    value: '${progress.totalCompletedLessons}',
                  ),
                  _StatItem(
                    label: 'Cards Due',
                    value: '${review.dueCardCount}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Daily Goal & Reminders'),
              const SizedBox(height: 8),
              _DailyGoalSettings(review: review),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Achievements'),
              const SizedBox(height: 8),
              _AchievementsPanel(
                totalXp: totalXp,
                streak: streak,
                lessonsCompleted: progress.totalCompletedLessons,
                totalReviews: reviewStats['totalReviews'] ?? 0,
              ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Review Performance'),
              const SizedBox(height: 8),
              _StatsGrid(
                items: [
                  _StatItem(
                    label: 'Accuracy',
                    value: '${accuracy.toStringAsFixed(0)}%',
                  ),
                  _StatItem(
                    label: 'Total Reviews',
                    value: '${reviewStats['totalReviews'] ?? 0}',
                  ),
                  _StatItem(
                    label: 'New Cards',
                    value: '${reviewStats['newCards'] ?? 0}',
                  ),
                  _StatItem(
                    label: 'Mature Cards',
                    value: '${reviewStats['matureCards'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.read<AuthService>().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyGoalSettings extends StatelessWidget {
  final ReviewProvider review;
  const _DailyGoalSettings({required this.review});

  @override
  Widget build(BuildContext context) {
    final goal = review.dailyGoalCards;
    final reminder = review.reminderTimeOfDay;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily goal: $goal cards',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: goal.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: '$goal',
            onChanged: (value) =>
                review.setDailyGoalCards(value.round()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reminder == null
                  ? 'Reminder: Off'
                  : 'Reminder: ${reminder.format(context)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: reminder == null
                      ? null
                      : () => review.setReminderTime(null),
                    child: const Text('Clear'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = TimeOfDay.now();
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: now,
                      );
                      if (picked != null) {
                        await review.setReminderTime(picked);
                      }
                    },
                    child: const Text('Set time'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementsPanel extends StatelessWidget {
  final int totalXp;
  final int streak;
  final int lessonsCompleted;
  final int totalReviews;

  const _AchievementsPanel({
    required this.totalXp,
    required this.streak,
    required this.lessonsCompleted,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Achievement(
        title: 'First Steps',
        description: 'Complete 1 lesson',
        achieved: lessonsCompleted >= 1,
      ),
      _Achievement(
        title: 'Consistent Learner',
        description: 'Reach a 3‑day streak',
        achieved: streak >= 3,
      ),
      _Achievement(
        title: 'Committed',
        description: 'Reach a 7‑day streak',
        achieved: streak >= 7,
      ),
      _Achievement(
        title: 'Review Pro',
        description: 'Review 25 cards',
        achieved: totalReviews >= 25,
      ),
      _Achievement(
        title: 'XP Collector',
        description: 'Earn 500 XP',
        achieved: totalXp >= 500,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements
          .map(
            (achievement) => _AchievementCard(achievement: achievement),
          )
          .toList(),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final bool achieved;

  const _Achievement({
    required this.title,
    required this.description,
    required this.achieved,
  });
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final bg = achievement.achieved
        ? PeacockTheme.peacockGreen.withAlpha(24)
        : Theme.of(context).cardColor;
    final border = achievement.achieved
        ? PeacockTheme.peacockGreen.withAlpha(120)
        : PeacockTheme.peacockBlue.withAlpha(40);
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                achievement.achieved ? Icons.emoji_events : Icons.lock,
                size: 18,
                color: achievement.achieved
                    ? PeacockTheme.peacockGreen
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? email;
  final String? photoUrl;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: PeacockTheme.peacockBlue.withAlpha(140),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: PeacockTheme.peacockBlue.withAlpha(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(item.value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
}
