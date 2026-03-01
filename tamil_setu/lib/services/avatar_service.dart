import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  static const String _avatarKey = 'avatar_override_asset';

  Future<String?> loadAvatarAsset() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_avatarKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setAvatarAsset(String? assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (assetPath == null || assetPath.isEmpty) {
      await prefs.remove(_avatarKey);
      return;
    }
    await prefs.setString(_avatarKey, assetPath);
  }
}
