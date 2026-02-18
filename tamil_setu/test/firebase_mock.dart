import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart'; // Required for BinaryMessenger and MethodCodec
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// FIX: Mock now inherits from MockPlatformInterfaceMixin and implements FirebasePlatform correctly
class MockFirebaseCorePlatform extends FirebasePlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    // FIX: Use FirebaseAppPlatform instead of the high-level FirebaseApp class
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      options ??
          const FirebaseOptions(
            apiKey: 'test',
            appId: 'test',
            messagingSenderId: 'test',
            projectId: 'test',
          ),
    );
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
        name,
        const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        ));
  }

  @override
  List<FirebaseAppPlatform> get apps => [];
}

// void setupFirebaseMocks() {
//   // FIX: Ensure you initialize the test environment
//   TestWidgetsFlutterBinding.ensureInitialized();
//   FirebasePlatform.instance = MockFirebaseCorePlatform();
// }

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebaseCorePlatform();

  // Define the codec used by Pigeon channels
  const MethodCodec authCodec = StandardMethodCodec();

  // The specific channels triggered by DashboardScreen's auth listeners
  final List<String> authChannels = [
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
    'plugins.flutter.io/firebase_auth',
  ];

  for (final channel in authChannels) {
    // Using setMockMessageHandler bypasses standard decoding and allows us
    // to return the exact binary ByteData the Pigeon codec requires.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channel, (ByteData? message) async {
      // Return a binary success envelope containing a null value
      return authCodec.encodeSuccessEnvelope(null);
    });
  }
}
