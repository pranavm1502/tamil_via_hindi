import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/curriculum.dart';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
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
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final overallProgress = progress.getOverallProgress(curriculum.length);
        final completedCount = progress.totalCompletedLessons;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completedCount/${curriculum.length} lessons',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: overallProgress / 100,
                backgroundColor: Colors.grey[300],
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '$overallProgress% Complete',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
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
