import 'package:flutter/material.dart';
import '../models/mistake_item.dart';
import '../services/mistake_storage_service.dart';

class MistakeProvider with ChangeNotifier {
  final MistakeStorageService _storage = MistakeStorageService();

  List<MistakeItem> _allMistakes = [];
  List<MistakeItem> _currentQueue = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  List<MistakeItem> get mistakes => _allMistakes;
  int get mistakeCount => _allMistakes.length;
  bool get isLoading => _isLoading;

  List<MistakeItem> get currentQueue => _currentQueue;
  int get currentIndex => _currentIndex;
  int get totalInSession => _currentQueue.length;
  bool get hasMore => _currentIndex < _currentQueue.length;
  MistakeItem? get currentMistake => hasMore ? _currentQueue[_currentIndex] : null;

  Future<void> loadMistakes() async {
    _isLoading = true;
    notifyListeners();
    _allMistakes = await _storage.loadMistakes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMistake(int lessonIndex, int wordIndex) async {
    await _storage.upsertMistake(lessonIndex, wordIndex);
    await loadMistakes();
  }

  void startSession({int maxCards = 10}) {
    final sorted = List<MistakeItem>.from(_allMistakes)
      ..sort((a, b) {
        final count = b.count.compareTo(a.count);
        if (count != 0) return count;
        return b.lastSeen.compareTo(a.lastSeen);
      });

    _currentQueue =
        sorted.length > maxCards ? sorted.sublist(0, maxCards) : sorted;
    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> resolveCurrent() async {
    if (!hasMore) return;
    final item = _currentQueue[_currentIndex];
    await _storage.removeMistake(item.lessonIndex, item.wordIndex);
    _allMistakes.removeWhere((m) => m.id == item.id);
    _currentQueue.removeAt(_currentIndex);
    if (_currentIndex >= _currentQueue.length) {
      _currentIndex = _currentQueue.length;
    }
    notifyListeners();
  }

  void skipCurrent() {
    if (!hasMore) return;
    _currentIndex++;
    notifyListeners();
  }
}
