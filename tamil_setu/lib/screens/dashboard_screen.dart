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
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: contentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressHeader(context, contentProvider.lessons.length),
                Expanded(
                  child: _buildLessonGrid(context, contentProvider.lessons),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, int totalLessons) {
    final progressProvider = context.watch<ProgressProvider>();
    
    // FIX 1: Using the correct getter from your ProgressProvider
    final completedCount = progressProvider.totalCompletedLessons;
    final completionPercentage =
        totalLessons > 0 ? (completedCount / totalLessons) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            // FIX 2: Resolving deprecated 'withOpacity' / 'withValues'
            color: Colors.black.withAlpha(13), // ~5% opacity
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress: $completedCount of $totalLessons Lessons',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completionPercentage.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonGrid(BuildContext context, List<Lesson> lessons) {
    final progressProvider = context.watch<ProgressProvider>();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, 
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        // Note: The lesson index passed to the provider should be the 0-based index
        // matching the list, which the provider uses internally (as per your code).
        
        // FIX 3 & 4: Using your ProgressProvider's methods
        final isLocked = progressProvider.isLessonLocked(index);
        final isCompleted = progressProvider.isLessonCompleted(index); 

        Color tileColor = Colors.white;
        Color iconColor = Colors.blueGrey;
        IconData iconData = Icons.lock_outline_rounded;

        if (!isLocked) {
          tileColor = isCompleted ? Colors.green.shade50 : Colors.orange.shade50;
          iconColor = isCompleted ? Colors.green.shade700 : Colors.orange.shade700;
          iconData = isCompleted ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded;
        }

        return GestureDetector(
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
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LessonScreen(
                      lesson: lesson,
                      lessonIndex: index, // Pass the 0-based index
                    ),
                  ));
                },
          child: Card(
            elevation: isLocked ? 1 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              // FIX 2: Resolving deprecated 'withOpacity' / 'withValues'
              side: BorderSide(
                color: isLocked ? Colors.grey.shade300 : iconColor.withAlpha(128), // ~50% opacity
                width: 2,
              ),
            ),
            color: tileColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    // FIX 2: Resolving deprecated 'withOpacity' / 'withValues'
                    backgroundColor: iconColor.withAlpha(38), // ~15% opacity
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Level ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      // FIX 2: Resolving deprecated 'withOpacity' / 'withValues'
                      color: iconColor.withAlpha(204), // ~80% opacity
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isLocked ? Colors.grey.shade500 : Colors.black87,
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