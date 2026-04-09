// lib/models/service_request_model.dart
// Pure data class — no Flutter, no Firebase

import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceCategory {
  plumbing,
  electrical,
  cleaning,
  acRepair,
  painting,
  carpentry,
  welding,
  applianceRepair,
  other,
}

enum TimeSlot {
  morning,    // 08:00 – 12:00
  afternoon,  // 12:00 – 17:00
  evening,    // 17:00 – 21:00
}

enum UrgencyLevel { normal, urgent }

enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

class ServiceRequest {
  final String? id;
  final String clientId;
  final ServiceCategory category;
  final String description;
  final DateTime preferredDate;
  final TimeSlot timeSlot;
  final String address;
  final String? apartmentInstructions;
  final UrgencyLevel urgency;
  final List<String> photoUrls;
  final RequestStatus status;
  final DateTime createdAt;

  const ServiceRequest({
    this.id,
    required this.clientId,
    required this.category,
    required this.description,
    required this.preferredDate,
    required this.timeSlot,
    required this.address,
    this.apartmentInstructions,
    this.urgency = UrgencyLevel.normal,
    this.photoUrls = const [],
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  // ── Firestore serialization ───────────────────────────────

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> map) {
    return ServiceRequest(
      id: id,
      clientId: map['clientId'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ServiceCategory.other,
      ),
      description: map['description'] ?? '',
      preferredDate: (map['preferredDate'] as Timestamp).toDate(),
      timeSlot: TimeSlot.values.firstWhere(
        (t) => t.name == map['timeSlot'],
        orElse: () => TimeSlot.morning,
      ),
      address: map['address'] ?? '',
      apartmentInstructions: map['apartmentInstructions'],
      urgency: UrgencyLevel.values.firstWhere(
        (u) => u.name == map['urgency'],
        orElse: () => UrgencyLevel.normal,
      ),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: RequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'category': category.name,
      'description': description,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'timeSlot': timeSlot.name,
      'address': address,
      'apartmentInstructions': apartmentInstructions,
      'urgency': urgency.name,
      'photoUrls': photoUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Display helpers ───────────────────────────────────────

  String get categoryLabel {
    switch (category) {
      case ServiceCategory.plumbing: return 'Plumbing';
      case ServiceCategory.electrical: return 'Electrical';
      case ServiceCategory.cleaning: return 'Cleaning';
      case ServiceCategory.acRepair: return 'AC Repair';
      case ServiceCategory.painting: return 'Painting';
      case ServiceCategory.carpentry: return 'Carpentry';
      case ServiceCategory.welding: return 'Welding';
      case ServiceCategory.applianceRepair: return 'Appliance Repair';
      case ServiceCategory.other: return 'Other';
    }
  }

  String get timeSlotLabel {
    switch (timeSlot) {
      case TimeSlot.morning: return 'Morning (08:00 – 12:00)';
      case TimeSlot.afternoon: return 'Afternoon (12:00 – 17:00)';
      case TimeSlot.evening: return 'Evening (17:00 – 21:00)';
    }
  }

  String get urgencyLabel =>
      urgency == UrgencyLevel.urgent ? 'Urgent' : 'Normal';

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending: return 'Pending';
      case RequestStatus.accepted: return 'Accepted';
      case RequestStatus.inProgress: return 'In Progress';
      case RequestStatus.completed: return 'Completed';
      case RequestStatus.cancelled: return 'Cancelled';
    }
  }
}
