import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../data/curriculum.dart'; // Import the new loader file

class ContentProvider with ChangeNotifier {
  List<Lesson> _lessons = [];
  bool _isLoading = true;

  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;

Future<void> loadContent() async {
  _isLoading = true;
  notifyListeners();

  try {
    // Call the function we created in Step 3
    _lessons = await loadCurriculumData();
  } catch (e) {
    // Optionally, log the error or show a fallback
    _lessons = [];
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}
