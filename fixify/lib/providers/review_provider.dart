// lib/providers/review_provider.dart
// All review Firestore logic — views never import Firebase

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../models/service_request_model.dart';

enum ReviewLoadState { idle, loading, loaded, error }
enum ReviewSubmitState { idle, loading, success, error }

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ─────────────────────────────────────────────────
  // Reviews the client has already submitted
  List<Review> _myReviews = [];

  // Completed bookings the client hasn't reviewed yet
  List<ServiceRequest> _pendingReviews = [];

  // Reviews a technician has received
  List<Review> _technicianReviews = [];
  double _averageRating = 0.0;

  ReviewLoadState _loadState = ReviewLoadState.idle;
  ReviewSubmitState _submitState = ReviewSubmitState.idle;
  String _errorMessage = '';

  StreamSubscription? _reviewsSub;
  StreamSubscription? _pendingSub;

  // ── Getters ───────────────────────────────────────────────
  List<Review> get myReviews => _myReviews;
  List<ServiceRequest> get pendingReviews => _pendingReviews;
  List<Review> get technicianReviews => _technicianReviews;
  double get averageRating => _averageRating;
  ReviewLoadState get loadState => _loadState;
  ReviewSubmitState get submitState => _submitState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadState == ReviewLoadState.loading;
  bool get isSubmitting => _submitState == ReviewSubmitState.loading;
  String? get uid => _auth.currentUser?.uid;

  // ── CLIENT: load submitted reviews + pending bookings ─────
  void listenToClientReviews() {
    if (uid == null) return;
    _loadState = ReviewLoadState.loading;
    notifyListeners();

    // Stream reviews this client has already submitted
    _reviewsSub?.cancel();
    _reviewsSub = _db
        .collection('reviews')
        .where('clientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        _myReviews = snap.docs
            .map((d) => Review.fromMap(d.id, _hydrateTimestamp(d.data())))
            .toList();
        _loadState = ReviewLoadState.loaded;
        notifyListeners();
      },
      onError: (_) {
        _loadState = ReviewLoadState.error;
        _errorMessage = 'Failed to load reviews.';
        notifyListeners();
      },
    );

    // Stream completed bookings not yet reviewed
    _pendingSub?.cancel();
    _pendingSub = _db
        .collection('service_requests')
        .where('clientId', isEqualTo: uid)
        .where('status', isEqualTo: RequestStatus.completed.name)
        .snapshots()
        .listen(
      (snap) async {
        final completed = snap.docs
            .map((d) => ServiceRequest.fromMap(d.id, _hydrateRequestTimestamps(d.data())))
            .toList();

        // Get IDs of requests already reviewed
        final reviewedRequestIds =
            _myReviews.map((r) => r.requestId).toSet();

        _pendingReviews = completed
            .where((r) => !reviewedRequestIds.contains(r.id))
            .toList();

        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ── TECHNICIAN: load received reviews ─────────────────────
  void listenToTechnicianReviews(String technicianId) {
    _loadState = ReviewLoadState.loading;
    notifyListeners();

    _reviewsSub?.cancel();
    _reviewsSub = _db
        .collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        _technicianReviews = snap.docs
            .map((d) => Review.fromMap(d.id, _hydrateTimestamp(d.data())))
            .toList();

        // Compute average rating
        if (_technicianReviews.isNotEmpty) {
          final sum = _technicianReviews.fold(0, (acc, r) => acc + r.rating);
          _averageRating = sum / _technicianReviews.length;
        } else {
          _averageRating = 0.0;
        }

        _loadState = ReviewLoadState.loaded;
        notifyListeners();
      },
      onError: (_) {
        _loadState = ReviewLoadState.error;
        _errorMessage = 'Failed to load reviews.';
        notifyListeners();
      },
    );
  }

  // ── CLIENT: submit a review ───────────────────────────────
  Future<void> submitReview({
    required String technicianId,
    required String requestId,
    required int rating,
    required String comment,
  }) async {
    if (uid == null) return;

    _submitState = ReviewSubmitState.loading;
    notifyListeners();

    try {
      // Guard: prevent duplicate reviews for the same booking
      final existing = await _db
          .collection('reviews')
          .where('requestId', isEqualTo: requestId)
          .where('clientId', isEqualTo: uid)
          .get();

      if (existing.docs.isNotEmpty) {
        _submitState = ReviewSubmitState.error;
        _errorMessage = 'You already reviewed this booking.';
        notifyListeners();
        return;
      }

      final review = Review(
        clientId: uid!,
        technicianId: technicianId,
        requestId: requestId,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();

      // Write the review doc
      final reviewRef = _db.collection('reviews').doc();
      batch.set(reviewRef, {
        ...review.toMap(),
        'createdAt': Timestamp.now(),
      });

      // Update technician's average rating in their profile doc
      // (denormalized for fast reads on technician cards)
      final techRef =
          _db.collection('technician_profiles').doc(technicianId);
      final techSnap = await techRef.get();
      if (techSnap.exists) {
        final data = techSnap.data()!;
        final currentTotal =
            (data['totalRating'] as num?)?.toDouble() ?? 0.0;
        final currentCount =
            (data['reviewCount'] as num?)?.toInt() ?? 0;
        final newCount = currentCount + 1;
        final newAverage = (currentTotal + rating) / newCount;

        batch.update(techRef, {
          'totalRating': currentTotal + rating,
          'reviewCount': newCount,
          'averageRating': double.parse(newAverage.toStringAsFixed(1)),
        });
      }

      await batch.commit();
      _submitState = ReviewSubmitState.success;
    } catch (e) {
      _submitState = ReviewSubmitState.error;
      _errorMessage = 'Failed to submit review. Please try again.';
    } finally {
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  Map<String, dynamic> _hydrateTimestamp(Map<String, dynamic> data) => {
        ...data,
        'createdAt': data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      };

  Map<String, dynamic> _hydrateRequestTimestamps(
      Map<String, dynamic> data) => {
        ...data,
        'preferredDate': data['preferredDate'] is Timestamp
            ? (data['preferredDate'] as Timestamp).toDate()
            : DateTime.now(),
        'createdAt': data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      };

  void resetSubmitState() {
    _submitState = ReviewSubmitState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }
}
