import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResponse {
  AuthResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class FirebaseAuthService {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.sendEmailVerification();

      return AuthResponse(
        success: true,
        message: 'Verification email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResponse(success: false, message: _mapError(e));
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Signup failed. Please try again.',
      );
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.reload();
      final user = auth.currentUser;
      if (user == null) {
        return AuthResponse(success: false, message: 'Login failed.');
      }
      if (!user.emailVerified) {
        return AuthResponse(
          success: false,
          message: 'Please verify your email before login.',
        );
      }
      return AuthResponse(success: true, message: 'Login successful.');
    } on FirebaseAuthException catch (e) {
      return AuthResponse(success: false, message: _mapError(e));
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Login failed. Please try again.',
      );
    }
  }

  Future<AuthResponse> resendVerificationEmail(String email) async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null && user.email == email && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResponse(
          success: true,
          message: 'Verification email sent again.',
        );
      }
      return AuthResponse(
        success: false,
        message: 'Login with this account once, then resend verification.',
      );
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Could not resend verification now.',
      );
    }
  }

  Future<AuthResponse> logout() async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      await FirebaseAuth.instance.signOut();
      return AuthResponse(success: true, message: 'Logged out successfully.');
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Logout failed. Please try again.',
      );
    }
  }

  Future<AuthResponse> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return AuthResponse(
        success: true,
        message: 'Password reset email sent. Check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResponse(success: false, message: _mapError(e));
    } catch (_) {
      return AuthResponse(
        success: false,
        message: 'Could not send reset email. Please try again.',
      );
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    if (!_isFirebaseReady) {
      return AuthResponse(
        success: false,
        message: 'Firebase not configured. Please connect Firebase project first.',
      );
    }
    try {
      final auth = FirebaseAuth.instance;
      UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        credential = await auth.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          return AuthResponse(
            success: false,
            message: 'Google sign-in cancelled.',
          );
        }
        final googleAuth = await googleUser.authentication;
        final googleCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await auth.signInWithCredential(googleCredential);
      }
      if (credential.user == null) {
        return AuthResponse(
          success: false,
          message: 'Google sign-in failed. Please try again.',
        );
      }
      return AuthResponse(success: true, message: 'Signed in with Google.');
    } on FirebaseAuthException catch (e) {
      return AuthResponse(success: false, message: _mapError(e));
    } on FirebaseException catch (e) {
      final code = e.code.isEmpty ? 'unknown' : e.code;
      final message = (e.message == null || e.message!.trim().isEmpty)
          ? 'Google sign-in failed.'
          : e.message!.trim();
      return AuthResponse(
        success: false,
        message: 'Firebase error [$code]: $message',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Google sign-in error: $e',
      );
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Authentication.';
      case 'unauthorized-domain':
        return 'This domain is not authorized. Add localhost in Firebase Auth authorized domains.';
      case 'popup-blocked':
        return 'Popup was blocked by the browser. Allow popups and try Google sign-in again.';
      case 'popup-closed-by-user':
        return 'Google sign-in popup was closed before completing login.';
      case 'network-request-failed':
        return 'Network issue while contacting Firebase. Check internet and retry.';
      case 'email-already-in-use':
        return 'Account already exists. Please login.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No account found. Please create account first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        final raw = e.message?.trim();
        if (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'error') {
          return raw;
        }
        return 'Auth failed (${e.code}). Check Firebase auth settings.';
    }
  }
}
