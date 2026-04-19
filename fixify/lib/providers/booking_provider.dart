// lib/providers/booking_provider.dart
// All booking Firestore logic — views never import Firebase

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';

enum BookingLoadState { idle, loading, loaded, error }
enum BookingActionState { idle, loading, success, error }

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ─────────────────────────────────────────────────
  List<ServiceRequest> _clientBookings = [];
  List<ServiceRequest> _incomingJobs = [];
  List<ServiceRequest> _myJobs = [];

  BookingLoadState _loadState = BookingLoadState.idle;
  BookingActionState _actionState = BookingActionState.idle;
  String _errorMessage = '';

  StreamSubscription<QuerySnapshot>? _clientSub;
  StreamSubscription<QuerySnapshot>? _incomingSub;
  StreamSubscription<QuerySnapshot>? _myJobsSub;

  // ── Getters ──────────────────────────────────────────────
  List<ServiceRequest> get clientBookings => _clientBookings;
  List<ServiceRequest> get incomingJobs => _incomingJobs;
  List<ServiceRequest> get myJobs => _myJobs;
  BookingLoadState get loadState => _loadState;
  BookingActionState get actionState => _actionState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadState == BookingLoadState.loading;
  bool get isActing => _actionState == BookingActionState.loading;
  String? get uid => _auth.currentUser?.uid;

  // ── CLIENT: stream my bookings ────────────────────────────
  void listenToClientBookings() {
    if (uid == null) return;
    _loadState = BookingLoadState.loading;
    notifyListeners();

    _clientSub?.cancel();
    _clientSub = _db
        .collection('service_requests')
        .where('clientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        _clientBookings = snap.docs.map(_docToRequest).toList();
        _loadState = BookingLoadState.loaded;
        notifyListeners();
      },
      onError: (_) {
        _loadState = BookingLoadState.error;
        _errorMessage = 'Failed to load bookings.';
        notifyListeners();
      },
    );
  }

  // ── CLIENT: cancel a pending booking ──────────────────────
  Future<void> cancelBooking(String requestId) async {
    _actionState = BookingActionState.loading;
    notifyListeners();
    try {
      await _db
          .collection('service_requests')
          .doc(requestId)
          .update({'status': RequestStatus.cancelled.name});
      _actionState = BookingActionState.success;
    } catch (e) {
      _actionState = BookingActionState.error;
      _errorMessage = 'Failed to cancel booking.';
    } finally {
      notifyListeners();
    }
  }

  // ── TECHNICIAN: stream incoming jobs by trade ─────────────
  void listenToIncomingJobs(String trade) {
    if (uid == null) return;
    _loadState = BookingLoadState.loading;
    notifyListeners();

    _incomingSub?.cancel();
    _incomingSub = _db
        .collection('service_requests')
        .where('status', isEqualTo: RequestStatus.pending.name)
        .where('category', isEqualTo: _tradeToCategory(trade))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        // Filter out jobs the technician already declined
        _incomingJobs = snap.docs
            .map(_docToRequest)
            .where((r) => !(r.declinedBy ?? []).contains(uid))
            .toList();
        _loadState = BookingLoadState.loaded;
        notifyListeners();
      },
      onError: (_) {
        _loadState = BookingLoadState.error;
        _errorMessage = 'Failed to load jobs.';
        notifyListeners();
      },
    );
  }

  // ── TECHNICIAN: stream my accepted/in-progress/completed jobs
  void listenToMyJobs() {
    if (uid == null) return;

    _myJobsSub?.cancel();
    _myJobsSub = _db
        .collection('service_requests')
        .where('technicianId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        _myJobs = snap.docs.map(_docToRequest).toList();
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ── TECHNICIAN: accept a job ──────────────────────────────
  Future<void> acceptJob(String requestId) async {
    if (uid == null) return;
    _actionState = BookingActionState.loading;
    notifyListeners();
    try {
      await _db.collection('service_requests').doc(requestId).update({
        'technicianId': uid,
        'status': RequestStatus.accepted.name,
        'acceptedAt': Timestamp.now(),
      });
      _actionState = BookingActionState.success;
    } catch (e) {
      _actionState = BookingActionState.error;
      _errorMessage = 'Failed to accept job.';
    } finally {
      notifyListeners();
    }
  }

  // ── TECHNICIAN: decline a job ─────────────────────────────
  Future<void> declineJob(String requestId) async {
    if (uid == null) return;
    try {
      await _db.collection('service_requests').doc(requestId).update({
        'declinedBy': FieldValue.arrayUnion([uid]),
      });
      // Local removal for instant UI feedback
      _incomingJobs.removeWhere((r) => r.id == requestId);
      notifyListeners();
    } catch (_) {}
  }

  // ── TECHNICIAN: update job status ─────────────────────────
  Future<void> updateJobStatus(
      String requestId, RequestStatus newStatus) async {
    _actionState = BookingActionState.loading;
    notifyListeners();
    try {
      await _db
          .collection('service_requests')
          .doc(requestId)
          .update({'status': newStatus.name});
      _actionState = BookingActionState.success;
    } catch (e) {
      _actionState = BookingActionState.error;
      _errorMessage = 'Failed to update status.';
    } finally {
      notifyListeners();
    }
  }

  // ── Single booking stream (for tracking screen) ───────────
  Stream<ServiceRequest?> streamBooking(String requestId) {
    return _db
        .collection('service_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) => doc.exists ? _docToRequest(doc) : null);
  }

  // ── Helpers ───────────────────────────────────────────────
  ServiceRequest _docToRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest.fromMap(doc.id, {
      ...data,
      'preferredDate': data['preferredDate'] is Timestamp
          ? (data['preferredDate'] as Timestamp).toDate()
          : DateTime.now(),
      'createdAt': data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      'declinedBy': data['declinedBy'],
    });
  }

  /// Maps technician trade string to the ServiceCategory enum name
  /// used in Firestore so the query filter works correctly.
  String _tradeToCategory(String trade) {
    const map = {
      'Plumber':          'plumbing',
      'Electrician':      'electrical',
      'AC Repair':        'acRepair',
      'Painter':          'painting',
      'Carpenter':        'carpentry',
      'Cleaning':         'cleaning',
      'Welder':           'welding',
      'Appliance Repair': 'applianceRepair',
    };
    return map[trade] ?? 'other';
  }

  void resetActionState() {
    _actionState = BookingActionState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _clientSub?.cancel();
    _incomingSub?.cancel();
    _myJobsSub?.cancel();
    super.dispose();
  }
}
