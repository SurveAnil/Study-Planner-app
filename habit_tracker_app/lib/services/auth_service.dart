import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '472149507943-i6tuqejohomc2g5u1nh0fqda7re1isdh.apps.googleusercontent.com'
        : null,
  );

  /// Sign in with Google and Firebase
  /// Returns the Firebase User if successful, null if cancelled or error
  /// Throws an exception with user-friendly error messages for UI error handling
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Recommended flow for Web: Use Firebase's dedicated Web popup
        // This avoids the 'google_sign_in' plugin's web limitations and People API requirements
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Optional: you can add more scopes if required
        // googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
        
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        
        final User? user = userCredential.user;
        if (user == null) {
          throw Exception('Failed to create Firebase user');
        }
        
        print('✅ Successfully signed in (Web): ${user.email}');
        return user;
      }

      // Existing mobile/desktop flow
      // Trigger the Google Sign-In popup
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User cancelled the sign-in
      if (googleUser == null) {
        throw Exception('Sign-in cancelled by user');
      }

      // Get the authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      // Verify we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to retrieve authentication tokens');
      }

      // Create Firebase credential with Google tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create Firebase user');
      }
      
      print('✅ Successfully signed in: ${user.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage = 'Firebase authentication error';
      
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with the same email';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials provided';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google Sign-In is not enabled for this project';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled';
          break;
        case 'user-not-found':
          errorMessage = 'User account not found';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid credentials';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'credential-already-in-use':
          errorMessage = 'This credential is already in use';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }
      
      print('❌ Sign-in error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      // Handle generic errors
      String errorMessage = 'An unexpected error occurred during sign-in';
      
      if (e.toString().contains('Sign-in cancelled')) {
        errorMessage = 'Sign-in cancelled by user';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection';
      }
      
      print('❌ Unexpected error: $e');
      throw Exception(errorMessage);
    }
  }

  /// Sign out the current user from both Google and Firebase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('✅ Successfully signed out');
    } catch (e) {
      print('❌ Sign-out error: $e');
      rethrow;
    }
  }

  /// Get the currently authenticated user
  User? get currentUser => _auth.currentUser;
  
  /// Check if a user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;
  
  /// Get the current user's ID token for backend authentication
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('❌ Error getting ID token: $e');
      return null;
    }
  }
}
