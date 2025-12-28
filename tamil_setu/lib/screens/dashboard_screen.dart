import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/peacock_mascot.dart';
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
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: contentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView( // FIX: Replaced Column with CustomScrollView
              slivers: [
                // 1. Animated Mascot
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: PeacockMascot(message: 'नमस्ते! आज तमिल सीखते हैं?'),
                  ),
                ),
                
                // 2. Progress Header
                SliverToBoxAdapter(
                  child: _ProgressHeader(totalLessons: contentProvider.lessons.length),
                ),
                
                // 3. Lesson Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = contentProvider.lessons[index];
                        return _LessonTile(lesson: lesson, index: index);
                      },
                      childCount: contentProvider.lessons.length,
                    ),
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
        final completedCount = progress.totalCompletedLessons;
        final overallProgress = progress.getOverallProgress(totalLessons);

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
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
        final Color cardColor = isLocked ? Theme.of(context).cardColor.withAlpha(179) : isCompleted ? Colors.green.shade50 : Colors.orange.shade50;

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