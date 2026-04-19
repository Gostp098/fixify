import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_profile_model.dart';

enum ProfileSaveState { idle, loading, success, error }

class TechnicianProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TechnicianProfile? _profile;
  ProfileSaveState _saveState = ProfileSaveState.idle;
  String _errorMessage = '';
  bool _isLoadingProfile = false;

  // ── Getters ──────────────────────────────────────────────
  TechnicianProfile? get profile => _profile;
  ProfileSaveState get saveState => _saveState;
  String get errorMessage => _errorMessage;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSaving => _saveState == ProfileSaveState.loading;
  String? get uid => _auth.currentUser?.uid;

  // ── Load existing profile ─────────────────────────────────
  Future<void> loadProfile() async {
    if (uid == null) return;
    _isLoadingProfile = true;
    notifyListeners();

    try {
      final doc = await _db
          .collection('technician_profiles')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _profile = TechnicianProfile.fromMap(uid!, doc.data()!);
      }
    } catch (_) {
      _profile = null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ── Save / update profile ─────────────────────────────────
  Future<void> saveProfile({
    required String headline,
    required String trade,
    required double hourlyRate,
    required int yearsOfExperience,
    required int serviceRadius,
    required String bio,
    String? photoUrl,
    String? licenseUrl,
  }) async {
    if (uid == null) {
      _setError('Not authenticated');
      return;
    }

    _saveState = ProfileSaveState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final updated = TechnicianProfile(
        uid: uid!,
        headline: headline.trim(),
        trade: trade,
        hourlyRate: hourlyRate,
        yearsOfExperience: yearsOfExperience,
        serviceRadius: serviceRadius,
        bio: bio.trim(),
        photoUrl: photoUrl ?? _profile?.photoUrl,
        licenseUrl: licenseUrl ?? _profile?.licenseUrl,
        isOnline: _profile?.isOnline ?? false,
        profileComplete: true,
        rating: _profile?.rating ?? 0.0,
        totalReviews: _profile?.totalReviews ?? 0,
      );

      await _db
          .collection('technician_profiles')
          .doc(uid)
          .set(updated.toMap(), SetOptions(merge: true));

      // Mark profileComplete on the users doc
      await _db
          .collection('users')
          .doc(uid)
          .update({'profileComplete': true});

      _profile = updated;
      _saveState = ProfileSaveState.success;
    } catch (e) {
      _setError('Failed to save profile: ${e.toString()}');
    } finally {
      notifyListeners();
    }
  }

  // ── Toggle online / offline ───────────────────────────────
  Future<void> toggleOnline(bool value) async {
    if (uid == null) return;
    try {
      await _db
          .collection('technician_profiles')
          .doc(uid)
          .update({'isOnline': value});
      if (_profile != null) {
        _profile = _profile!.copyWith(isOnline: value);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Reset state after navigation ──────────────────────────
  void resetSaveState() {
    _saveState = ProfileSaveState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _saveState = ProfileSaveState.error;
    notifyListeners();
  }
}
