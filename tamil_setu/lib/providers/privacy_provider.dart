import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyProvider extends ChangeNotifier {
  static const int minorAge = 13;
  static const String _keyBirthYear = 'privacy_birth_year';
  static const String _keyTrackingAllowed = 'privacy_tracking_allowed';
  static const String _keySocialEnabled = 'privacy_social_enabled';
  static const String _keyNotificationsEnabled =
      'privacy_notifications_enabled';
  static const String _keyChildMode = 'privacy_child_mode';
  static const String _keyConsentComplete = 'privacy_consent_complete';

  int? _birthYear;
  bool _trackingAllowed = false;
  bool _socialEnabled = false;
  bool _notificationsEnabled = false;
  bool _childMode = false;
  bool _consentComplete = false;

  int? get birthYear => _birthYear;
  bool get onboardingComplete => _birthYear != null;
  bool get trackingAllowed => _trackingAllowed;
  bool get socialEnabled => _socialEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get childMode => _childMode;
  bool get consentComplete => _consentComplete;

  bool get isMinor {
    if (_birthYear == null) return false;
    return _ageFromYear(_birthYear!) < minorAge;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _birthYear = prefs.getInt(_keyBirthYear);
    _trackingAllowed = prefs.getBool(_keyTrackingAllowed) ?? false;
    _socialEnabled = prefs.getBool(_keySocialEnabled) ?? false;
    _notificationsEnabled =
      prefs.getBool(_keyNotificationsEnabled) ?? false;
    _childMode = prefs.getBool(_keyChildMode) ?? false;
    _consentComplete = prefs.getBool(_keyConsentComplete) ?? false;

    if (_birthYear != null &&
        !_hasAnyStoredFlags(prefs) &&
        _birthYear != null) {
      _applyDefaultsForYear(_birthYear!);
      await _persist(prefs);
    }

    notifyListeners();
  }

  Future<void> completeOnboarding({required int birthYear}) async {
    _birthYear = birthYear;
    _applyDefaultsForYear(birthYear);
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  Future<void> completeAdultConsent({
    required bool trackingAllowed,
    required bool socialEnabled,
    required bool notificationsEnabled,
  }) async {
    _trackingAllowed = trackingAllowed;
    _socialEnabled = socialEnabled;
    _notificationsEnabled = notificationsEnabled;
    _childMode = false;
    _consentComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  int _ageFromYear(int year) {
    final now = DateTime.now();
    return now.year - year;
  }

  bool _hasAnyStoredFlags(SharedPreferences prefs) {
    return prefs.containsKey(_keyTrackingAllowed) ||
        prefs.containsKey(_keySocialEnabled) ||
      prefs.containsKey(_keyNotificationsEnabled) ||
      prefs.containsKey(_keyConsentComplete) ||
        prefs.containsKey(_keyChildMode);
  }

  void _applyDefaultsForYear(int year) {
    final minor = _ageFromYear(year) < minorAge;
    _childMode = minor;
    _trackingAllowed = false;
    _socialEnabled = false;
    _notificationsEnabled = false;
    _consentComplete = minor;
  }

  Future<void> _persist(SharedPreferences prefs) async {
    if (_birthYear != null) {
      await prefs.setInt(_keyBirthYear, _birthYear!);
    }
    await prefs.setBool(_keyTrackingAllowed, _trackingAllowed);
    await prefs.setBool(_keySocialEnabled, _socialEnabled);
    await prefs.setBool(_keyNotificationsEnabled, _notificationsEnabled);
    await prefs.setBool(_keyChildMode, _childMode);
    await prefs.setBool(_keyConsentComplete, _consentComplete);
  }
}
