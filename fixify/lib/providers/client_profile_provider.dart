// ============================================================
// CONTROLLER — lib/providers/client_profile_provider.dart
// All business logic, Firebase calls, state management
// The View never touches Firebase directly
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_profile_model.dart';

enum ProfileSaveState { idle, loading, success, error }

class ClientProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ClientProfile? _profile;
  ProfileSaveState _saveState = ProfileSaveState.idle;
  String _errorMessage = '';
  bool _isLoadingProfile = false;

  // ── Getters ──────────────────────────────────────────────
  ClientProfile? get profile => _profile;
  ProfileSaveState get saveState => _saveState;
  String get errorMessage => _errorMessage;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSaving => _saveState == ProfileSaveState.loading;
  String? get uid => _auth.currentUser?.uid;

  // ── Load existing profile from Firestore ─────────────────
  Future<void> loadProfile() async {
    if (uid == null) return;
    _isLoadingProfile = true;
    notifyListeners();

    try {
      final doc = await _db
          .collection('client_profiles')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _profile = ClientProfile.fromMap(uid!, doc.data()!);
      }
    } catch (e) {
      // Profile doesn't exist yet — that's fine
      _profile = null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ── Save profile to Firestore ─────────────────────────────
  Future<void> saveProfile({
    required String address,
    required String city,
    required Gender gender,
    required ContactMethod preferredContact,
    String? alternativePhone,
    String? photoUrl,
  }) async {
    if (uid == null) {
      _setError('Not authenticated');
      return;
    }

    _saveState = ProfileSaveState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedProfile = ClientProfile(
        uid: uid!,
        address: address.trim(),
        city: city.trim(),
        gender: gender,
        preferredContact: preferredContact,
        alternativePhone: alternativePhone?.trim().isEmpty == true
            ? null
            : alternativePhone?.trim(),
        photoUrl: photoUrl ?? _profile?.photoUrl,
        profileComplete: true,
      );

      // Save to client_profiles collection
      await _db
          .collection('client_profiles')
          .doc(uid)
          .set(updatedProfile.toMap(), SetOptions(merge: true));

      // Mark profile complete on main user doc
      await _db
          .collection('users')
          .doc(uid)
          .update({'profileComplete': true});

      _profile = updatedProfile;
      _saveState = ProfileSaveState.success;
    } catch (e) {
      _setError('Failed to save profile: ${e.toString()}');
    } finally {
      notifyListeners();
    }
  }

  // ── Reset state after navigation ─────────────────────────
  void resetSaveState() {
    _saveState = ProfileSaveState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────
  void _setError(String message) {
    _errorMessage = message;
    _saveState = ProfileSaveState.error;
    notifyListeners();
  }
}
