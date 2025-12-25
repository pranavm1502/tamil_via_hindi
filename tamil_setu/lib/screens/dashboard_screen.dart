import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/curriculum.dart';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import 'lesson_screen.dart';

/// Main dashboard screen showing all available lessons.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tamil Setu (हिंदी ➡️ தமிழ்)"),
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
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: curriculum.length,
              itemBuilder: (context, index) {
                final lesson = curriculum[index];
                return _LessonCard(
                  lesson: lesson,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final overallProgress = progress.getOverallProgress(curriculum.length);
        final completedCount = progress.totalCompletedLessons;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '$completedCount/${curriculum.length} lessons',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: overallProgress / 100,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '$overallProgress% Complete',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int index;

  const _LessonCard({
    required this.lesson,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final isCompleted = progress.isLessonCompleted(index);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green : Colors.orange,
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
            title: Text(
              lesson.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.description),
                if (isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Completed ✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonScreen(
                    lesson: lesson,
                    lessonIndex: index,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
