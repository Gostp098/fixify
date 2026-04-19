// lib/providers/auth_provider.dart
// All auth logic lives here — views never import firebase_auth or cloud_firestore

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthState { idle, loading, success, error }

// Simple value classes replacing Dart records for compatibility
class RememberMeResult {
  final bool remembered;
  final String email;
  const RememberMeResult({required this.remembered, required this.email});
}

class LoginResult {
  final String role;
  final bool profileComplete;
  const LoginResult({required this.role, required this.profileComplete});
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthState _state = AuthState.idle;
  String _errorMessage = '';
  String _successMessage = '';

  // ── Getters ──────────────────────────────────────────────
  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  bool get isLoading => _state == AuthState.loading;
  User? get currentUser => _auth.currentUser;

  // ── Remember Me ──────────────────────────────────────────

  static const _rememberMeKey = 'remember_me';
  static const _savedEmailKey = 'saved_email';

  Future<void> saveRememberMe(String email, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
    if (remember) {
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<RememberMeResult> loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_savedEmailKey) ?? '';
    return RememberMeResult(remembered: remembered, email: email);
  }

  // ── Login ─────────────────────────────────────────────────
  Future<LoginResult> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    _setState(AuthState.loading);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await saveRememberMe(email.trim(), rememberMe);

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      final data = doc.data() ?? {};
      final role = data['role'] as String? ?? 'client';
      final profileComplete = data['profileComplete'] as bool? ?? false;

      _setState(AuthState.success);
      return LoginResult(role: role, profileComplete: profileComplete);
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      rethrow;
    } catch (e) {
      _setError('Login failed. Please try again.');
      rethrow;
    }
  }

  // ── Register ──────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    _setState(AuthState.loading);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;
      await cred.user!.sendEmailVerification();

      await _db.collection('users').doc(uid).set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role.toLowerCase(),
        'profileComplete': false,
        'emailVerified': false,
        'createdAt': Timestamp.now(),
      });

      _successMessage =
          'Account created! Please check your email to verify your address.';
      _setState(AuthState.success);
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      rethrow;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      rethrow;
    }
  }

  // ── Password reset ────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    _setState(AuthState.loading);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _successMessage = 'Password reset link sent to $email';
      _setState(AuthState.success);
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      rethrow;
    }
  }

  // ── Resend verification ───────────────────────────────────
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    resetState();
  }

  // ── State helpers ─────────────────────────────────────────
  void resetState() {
    _state = AuthState.idle;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }

  void _setState(AuthState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _state = AuthState.error;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
