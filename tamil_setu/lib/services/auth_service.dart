import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Use the singleton instance for version 7.x
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Track initialization to call it exactly once as required
  bool _isInitialized = false;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // It now throws a GoogleSignInException if the user cancels
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Access tokens are now obtained via the authorizationClient in v7.x
      final authorization = await googleUser.authorizationClient.authorizeScopes(['email']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
      
    } on GoogleSignInException catch (e) {
      // Handle the "canceled" state or other Google-specific errors here
      debugPrint('Google Sign-In Exception: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('General Sign-in Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-out Error: $e');
    }
  }
}