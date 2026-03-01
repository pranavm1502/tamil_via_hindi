import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'xp_rules.dart';

class XpTrackerService {
  static const String _xpAwardsKey = 'xp_item_awards_v1';

  Future<int> awardDailyXpForItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpAwardsKey);
    final Map<String, dynamic> data = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : (json.decode(raw) as Map<String, dynamic>);

    final now = DateTime.now();
    final today = _formatDay(now);

    final entry = data[itemId] as Map<String, dynamic>?;
    final lastAwardDay = entry?['last'] as String?;
    final everAwarded = entry?['ever'] == true;

    if (lastAwardDay == today) {
      return 0;
    }

    final xp = everAwarded
        ? XpRules.reviewItemCorrect
        : XpRules.newItemCorrect;

    data[itemId] = {
      'last': today,
      'ever': true,
    };

    await prefs.setString(_xpAwardsKey, json.encode(data));
    return xp;
  }

  String _formatDay(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
