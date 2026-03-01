import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/sentence_item.dart';

Future<List<SentenceItem>> loadSentenceData() async {
  try {
    final response = await rootBundle.loadString('assets/data/sentences.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => SentenceItem.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Error loading sentences: $e');
    return [];
  }
}
