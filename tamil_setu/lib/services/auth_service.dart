import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // 1. Nullable fields to allow truly silent mocks in tests
  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

  // Track initialization status
  bool _isInitialized = false;

  // 2. Getters that fallback to singletons only in production
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  GoogleSignIn get googleSignIn => _googleSignIn ?? GoogleSignIn.instance;

  // Expose the current user for centralized access
  User? get currentUser => auth.currentUser;

  // Auth state stream; tests can inject a mock FirebaseAuth
  Stream<User?> get userStream => auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // FIX: Removed '?' because the v7.x SDK throws exceptions on cancel rather than returning null
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // FIX: Removed 'await' because .authentication is not a Future
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Type is inferred correctly as non-nullable
      final authorization =
          await googleUser.authorizationClient.authorizeScopes(['email']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In Exception: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('General Sign-in Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await auth.signOut();
    } catch (e) {
      debugPrint('Sign-out Error: $e');
    }
  }
}
