import 'package:shared_preferences/shared_preferences.dart';

class LocalNameService {
  static const String _keyPrefix = 'local_display_name_';

  Future<String?> getName(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$uid');
  }

  Future<void> setName(String uid, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$uid', trimmed);
  }

  Future<void> clearName(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$uid');
  }
}
