import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFirebaseCorePlatform extends FirebasePlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
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
  FirebaseAppPlatform app([String name = '[DEFAULT]']) => FirebaseAppPlatform(
      name,
      const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test'));

  @override
  List<FirebaseAppPlatform> get apps => [];
}

void setupFirebaseMocks() {
  // 1. Initialize the core mock environment
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebaseCorePlatform();

  // 2. Set up the Pigeon codec for modern Firebase Auth/Core channels
  const StandardMessageCodec pigeonCodec = StandardMessageCodec();

  // These specific channels expect a non-null return value to avoid PlatformException(null-error)
  final List<String> pigeonChannels = [
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.optionsFromResource',
  ];

  for (final channel in pigeonChannels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channel, (ByteData? message) async {
      // FIX: Returning a List containing an empty Map satisfies the non-null return requirement
      // for the listener registration handles and the core options request.
      return pigeonCodec.encodeMessage(<Object?>[<Object?, Object?>{}]);
    });
  }

  // 3. Handle the legacy MethodChannel for backward compatibility
  const MethodCodec legacyCodec = StandardMethodCodec();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('plugins.flutter.io/firebase_auth',
          (ByteData? message) async {
    return legacyCodec.encodeSuccessEnvelope(null);
  });
}
