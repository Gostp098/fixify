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

  // ── Load client's saved address ───────────────────────────
  Future<void> loadSavedAddress() async {
    if (uid == null) return;
    _isLoadingAddress = true;
    notifyListeners();

    try {
      final doc = await _db.collection('client_profiles').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final address = data['address'] as String? ?? '';
        final city = data['city'] as String? ?? '';
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
      final now = DateTime.now();
      // Timestamp conversion happens here in the provider, not in the model
      final docData = {
        'clientId': uid,
        'technicianId': null,
        'category': category.name,
        'description': description.trim(),
        'preferredDate': Timestamp.fromDate(preferredDate),
        'timeSlot': timeSlot.name,
        'address': address.trim(),
        'apartmentInstructions': apartmentInstructions?.trim().isEmpty == true
            ? null
            : apartmentInstructions?.trim(),
        'urgency': urgency.name,
        'photoUrls': photoUrls,
        'status': RequestStatus.pending.name,
        'createdAt': Timestamp.fromDate(now),
      };

      final docRef = await _db.collection('service_requests').add(docData);
      _newRequestId = docRef.id;
      _submitState = SubmitState.success;
    } catch (e) {
      _setError('Failed to submit request: ${e.toString()}');
    } finally {
      notifyListeners();
    }
  }

  // ── Helper: convert Firestore doc → ServiceRequest ────────
  ServiceRequest _docToRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Convert Timestamps to DateTime before passing to pure model
    return ServiceRequest.fromMap(doc.id, {
      ...data,
      'preferredDate': data['preferredDate'] is Timestamp
          ? (data['preferredDate'] as Timestamp).toDate()
          : DateTime.now(),
      'createdAt': data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    });
  }

  // ── Reset ─────────────────────────────────────────────────
  void resetState() {
    _submitState = SubmitState.idle;
    _errorMessage = '';
    _newRequestId = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _submitState = SubmitState.error;
    notifyListeners();
  }
}
