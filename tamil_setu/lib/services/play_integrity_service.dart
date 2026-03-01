import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlayIntegrityService {
  static const MethodChannel _channel = MethodChannel('play_integrity');
  static const int cloudProjectNumber = 1088671298063;

  bool _isTestEnvironment() {
    return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<String?> requestToken({String? nonce}) async {
    if (_isTestEnvironment()) return null;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final payload = <String, Object?>{
      'cloudProjectNumber': cloudProjectNumber,
      // NOTE: Replace with a server-provided nonce for production validation.
      'nonce': nonce ?? _generateNonce(),
    };

    return _channel.invokeMethod<String>('requestIntegrityToken', payload);
  }

  String _generateNonce() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
