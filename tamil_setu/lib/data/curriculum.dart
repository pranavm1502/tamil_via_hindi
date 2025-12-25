import 'dart:convert';
import 'package:flutter/services.dart'; // Needed for rootBundle
import '../models/lesson.dart';

/// Loads the curriculum asynchronously from the JSON asset.
/// This replaces the old static list.
Future<List<Lesson>> loadCurriculumData() async {
  try {
    // 1. Read the file from assets
    final String response =
        await rootBundle.loadString('assets/data/master_content.json');

    // 2. Decode JSON
    final List<dynamic> data = json.decode(response);

    // 3. Convert JSON objects to Lesson objects
    return data.map((json) => Lesson.fromJson(json)).toList();
  } catch (e) {
    print("Error loading curriculum: $e");
    return []; // Return empty list on error to prevent crash
  }
}
