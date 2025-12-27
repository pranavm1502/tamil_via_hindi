import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson.dart'; 
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import 'lesson_screen.dart';

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
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
        ],
      ),
      body: contentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ProgressHeader(totalLessons: contentProvider.lessons.length),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: contentProvider.lessons.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final lesson = contentProvider.lessons[index];
                      return _LessonTile(
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
  final int totalLessons;

  const _ProgressHeader({required this.totalLessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        final overallProgress = progress.getOverallProgress(totalLessons);
        final completedCount = progress.totalCompletedLessons;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // FIX: Ensures no runtime error from 'withValues'/'withOpacity' on the BoxShadow
                color: Colors.black.withAlpha(25), 
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
                    '$completedCount/$totalLessons levels',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withAlpha(179),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalLessons == 0 ? 0 : completedCount / totalLessons,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                color: Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '${overallProgress.toStringAsFixed(0)}% Complete',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      theme.textTheme.bodyMedium?.color?.withAlpha(179),
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

class _LessonTile extends StatelessWidget {
  final Lesson lesson; 
  final int index;

  const _LessonTile({
    required this.lesson,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, child) {
        // Logic remains correct for 0-based index check
        final isLocked = progress.isLessonLocked(index);
        final isCompleted = progress.isLessonCompleted(index);

        // Define visual properties based on state
        final Color cardColor = isLocked
            ? Theme.of(context).cardColor.withAlpha(179)
            : isCompleted
                ? Colors.green.shade50
                : Colors.orange.shade50;
                
        final Color iconBgColor = isLocked
            ? Colors.grey.shade400
            : isCompleted
                ? Colors.green
                : Colors.orange;
                
        final IconData tileIcon = isLocked
            ? Icons.lock
            : isCompleted
                ? Icons.check
                : Icons.play_arrow;


        return Card(
            elevation: isLocked ? 0 : 4,
            // Card color is now based on state, no Opacity wrapper needed
            color: cardColor, 
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLocked
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete previous levels to unlock!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : () {
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: iconBgColor,
                      // The Icon is now directly rendered with the correct IconData
                      child: Icon(
                        tileIcon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lesson.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
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