// lib/providers/service_request_provider.dart
// All business logic and Firebase calls — View never touches Firestore

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';

enum SubmitState { idle, loading, success, error }

class ServiceRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SubmitState _submitState = SubmitState.idle;
  String _errorMessage = '';
  String? _newRequestId;
  String _savedAddress = '';
  bool _isLoadingAddress = false;

  // ── Getters ──────────────────────────────────────────────
  SubmitState get submitState => _submitState;
  String get errorMessage => _errorMessage;
  String? get newRequestId => _newRequestId;
  String get savedAddress => _savedAddress;
  bool get isLoadingAddress => _isLoadingAddress;
  bool get isSubmitting => _submitState == SubmitState.loading;
  String? get uid => _auth.currentUser?.uid;

  // ── Load client's saved address from their profile ────────
  Future<void> loadSavedAddress() async {
    if (uid == null) return;
    _isLoadingAddress = true;
    notifyListeners();

    try {
      final doc = await _db
          .collection('client_profiles')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final address = data['address'] ?? '';
        final city = data['city'] ?? '';
        _savedAddress = city.isNotEmpty && address.isNotEmpty
            ? '$address, $city'
            : address;
      }
    } catch (_) {
      _savedAddress = '';
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
  }

  // ── Submit new service request ────────────────────────────
  Future<void> submitRequest({
    required ServiceCategory category,
    required String description,
    required DateTime preferredDate,
    required TimeSlot timeSlot,
    required String address,
    String? apartmentInstructions,
    required UrgencyLevel urgency,
    List<String> photoUrls = const [],
  }) async {
    if (uid == null) {
      _setError('Not authenticated');
      return;
    }

    _submitState = SubmitState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final request = ServiceRequest(
        clientId: uid!,
        category: category,
        description: description.trim(),
        preferredDate: preferredDate,
        timeSlot: timeSlot,
        address: address.trim(),
        apartmentInstructions: apartmentInstructions?.trim().isEmpty == true
            ? null
            : apartmentInstructions?.trim(),
        urgency: urgency,
        photoUrls: photoUrls,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _db
          .collection('service_requests')
          .add(request.toMap());

      _newRequestId = docRef.id;
      _submitState = SubmitState.success;
    } catch (e) {
      _setError('Failed to submit request: ${e.toString()}');
    } finally {
      notifyListeners();
    }
  }

  // ── Reset after navigation ────────────────────────────────
  void resetState() {
    _submitState = SubmitState.idle;
    _errorMessage = '';
    _newRequestId = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _submitState = SubmitState.error;
    notifyListeners();
  }
}
