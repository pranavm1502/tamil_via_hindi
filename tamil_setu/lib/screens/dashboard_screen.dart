import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson.dart';
import '../models/checkpoint.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/peacock_mascot.dart';
import 'lesson_screen.dart';
import 'review_screen.dart';
import 'checkpoint_quiz_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentProvider = context.watch<ContentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamil Setu (हिंदी ➡️ தமிழ்)'),
        centerTitle: true,
        elevation: 2,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: contentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: PeacockMascot(message: 'नमस्ते! आज तमिल सीखते हैं?'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _ReviewButton(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ProgressHeader(totalLessons: contentProvider.lessons.length),
                ),
                _LessonsAndCheckpointsBuilder(
                  lessons: contentProvider.lessons,
                ),
              ],
            ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int totalLessons;
  const _ProgressHeader({required this.totalLessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final completedCount = progress.totalCompletedLessons;
        final overallProgress = progress.getOverallProgress(totalLessons);

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$completedCount/$totalLessons levels'),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalLessons == 0 ? 0 : completedCount / totalLessons,
                backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('${overallProgress.toStringAsFixed(0)}% Complete'),
            ],
          ),
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson; 
  final int index;
  const _LessonTile({required this.lesson, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final isLocked = progress.isLessonLocked(index);
        final isCompleted = progress.isLessonCompleted(index);
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isLocked
            ? Theme.of(context).cardColor.withAlpha(179)
            : isCompleted
                ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                : (isDark ? Colors.orange.shade900 : Colors.orange.shade50);

        return Card(
            elevation: isLocked ? 0 : 4,
            color: cardColor, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLocked ? () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete previous levels to unlock!')));
              } : () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LessonScreen(lesson: lesson, lessonIndex: index)));
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isLocked ? Colors.grey : (isCompleted ? Colors.green : Colors.orange),
                      child: Icon(isLocked ? Icons.lock : (isCompleted ? Icons.check : Icons.play_arrow), color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(lesson.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(lesson.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }
}

class _ReviewButton extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _ReviewButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final dueCount = reviewProvider.dueCardCount;
        final streak = reviewProvider.currentStreak;

        if (dueCount == 0 && reviewProvider.allCards.isEmpty) {
          // No cards created yet - don't show anything
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: dueCount > 0
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.purple.shade900
                  : Colors.purple.shade50)
              : Theme.of(context).cardColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: dueCount > 0
                ? () {
                    reviewProvider.startReviewSession();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReviewScreen()),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: dueCount > 0 ? Colors.purple : Colors.grey,
                    child: Icon(
                      dueCount > 0 ? Icons.auto_awesome : Icons.check_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dueCount > 0 ? 'Review Cards' : 'All Caught Up!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueCount > 0
                              ? '$dueCount card${dueCount != 1 ? 's' : ''} due for review'
                              : 'Come back later for more reviews',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (dueCount > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LessonsAndCheckpointsBuilder extends StatelessWidget {
  final List<Lesson> lessons;
  const _LessonsAndCheckpointsBuilder({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final checkpoints = CheckpointService.generateCheckpoints(lessons.length);
    final List<Widget> items = [];

    for (int i = 0; i < lessons.length; i++) {
      // Add lesson tile in 2-column grid
      if (i % 2 == 0) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 8),
            child: SizedBox(
              height: 180,
              child: _LessonTile(lesson: lessons[i], index: i),
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 16),
            child: SizedBox(
              height: 180,
              child: _LessonTile(lesson: lessons[i], index: i),
            ),
          ),
        );
      }

      // Add checkpoint after every 5 lessons
      if ((i + 1) % CheckpointService.lessonsPerSection == 0) {
        final checkpointIndex = (i + 1) ~/ CheckpointService.lessonsPerSection - 1;
        if (checkpointIndex < checkpoints.length) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              child: _CheckpointTile(checkpoint: checkpoints[checkpointIndex]),
            ),
          );
        }
      }
    }

    return SliverList(
      delegate: SliverChildListDelegate(items),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final Checkpoint checkpoint;
  const _CheckpointTile({required this.checkpoint});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final isLocked = progress.isCheckpointLocked(checkpoint.checkpointNumber);
        final isCompleted = progress.isCheckpointCompleted(checkpoint.checkpointNumber);

        return Card(
          elevation: isLocked ? 0 : 6,
          color: isCompleted
              ? Colors.purple.shade50
              : (isLocked ? Colors.grey.shade200 : Colors.purple.shade100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCompleted ? Colors.purple : (isLocked ? Colors.grey : Colors.purple.shade300),
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLocked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete all lessons in this section first!'),
                      ),
                    );
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckpointQuizScreen(checkpoint: checkpoint),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock
                        : (isCompleted ? Icons.check_circle : Icons.flag),
                    size: 48,
                    color: isLocked ? Colors.grey : Colors.purple,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              checkpoint.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.purple, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint.lessonRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isLocked ? Colors.grey : Colors.purple,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
