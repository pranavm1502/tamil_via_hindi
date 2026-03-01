import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mistake_item.dart';

class MistakeStorageService {
  static const String _mistakesKey = 'mistakes_v1';

  Future<List<MistakeItem>> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mistakesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> data = json.decode(raw);
      return data.map((item) => MistakeItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMistakes(List<MistakeItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_mistakesKey, raw);
  }

  Future<void> upsertMistake(int lessonIndex, int wordIndex) async {
    final items = await loadMistakes();
    final now = DateTime.now();
    final index = items.indexWhere(
      (item) =>
          item.lessonIndex == lessonIndex && item.wordIndex == wordIndex,
    );

    if (index == -1) {
      items.add(MistakeItem(
        lessonIndex: lessonIndex,
        wordIndex: wordIndex,
        count: 1,
        lastSeen: now,
      ));
    } else {
      final existing = items[index];
      items[index] = existing.copyWith(
        count: existing.count + 1,
        lastSeen: now,
      );
    }

    await saveMistakes(items);
  }

  Future<void> removeMistake(int lessonIndex, int wordIndex) async {
    final items = await loadMistakes();
    items.removeWhere(
      (item) =>
          item.lessonIndex == lessonIndex && item.wordIndex == wordIndex,
    );
    await saveMistakes(items);
  }

  Future<void> clearMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mistakesKey);
  }
}
