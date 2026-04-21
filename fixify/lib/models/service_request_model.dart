// lib/models/service_request_model.dart

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

// Extension so the view can call category.label cleanly
extension ServiceCategoryX on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.plumbing:        return 'Plumbing';
      case ServiceCategory.electrical:      return 'Electrical';
      case ServiceCategory.cleaning:        return 'Cleaning';
      case ServiceCategory.acRepair:        return 'AC Repair';
      case ServiceCategory.painting:        return 'Painting';
      case ServiceCategory.carpentry:       return 'Carpentry';
      case ServiceCategory.welding:         return 'Welding';
      case ServiceCategory.applianceRepair: return 'Appliance Repair';
      case ServiceCategory.other:           return 'Other';
    }
  }
}

enum TimeSlot {
  morning,   // 08:00 – 12:00
  afternoon, // 12:00 – 17:00
  evening,   // 17:00 – 21:00
}

// Extension so the view can call timeSlot.label cleanly
extension TimeSlotX on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:   return 'Morning (08:00 – 12:00)';
      case TimeSlot.afternoon: return 'Afternoon (12:00 – 17:00)';
      case TimeSlot.evening:   return 'Evening (17:00 – 21:00)';
    }
  }
}

enum UrgencyLevel { normal, urgent }

enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

class ServiceRequest {
  final String? id;
  final String clientId;
  final String? technicianId;
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
  final List<String>? declinedBy;

  const ServiceRequest({
    this.id,
    required this.clientId,
    this.technicianId,
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
    this.declinedBy,
  });

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> map) {
    return ServiceRequest(
      id: id,
      clientId: map['clientId'] ?? '',
      technicianId: map['technicianId'],
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ServiceCategory.other,
      ),
      description: map['description'] ?? '',
      preferredDate: map['preferredDate'] is DateTime
          ? map['preferredDate']
          : DateTime.now(),
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
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.now(),
      declinedBy: map['declinedBy'] != null
          ? List<String>.from(map['declinedBy'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'technicianId': technicianId,
      'category': category.name,
      'description': description,
      'preferredDate': preferredDate,
      'timeSlot': timeSlot.name,
      'address': address,
      'apartmentInstructions': apartmentInstructions,
      'urgency': urgency.name,
      'photoUrls': photoUrls,
      'status': status.name,
      'createdAt': createdAt,
      'declinedBy': declinedBy ?? [],
    };
  }

  // ── Convenience getters (kept for backward compat with existing views) ──────
  String get categoryLabel   => category.label;
  String get timeSlotLabel   => timeSlot.label;
  String get urgencyLabel    => urgency == UrgencyLevel.urgent ? 'Urgent' : 'Normal';

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:    return 'Pending';
      case RequestStatus.accepted:   return 'Accepted';
      case RequestStatus.inProgress: return 'In Progress';
      case RequestStatus.completed:  return 'Completed';
      case RequestStatus.cancelled:  return 'Cancelled';
    }
  }

  String get formattedDate =>
      '${preferredDate.day.toString().padLeft(2, '0')}/'
      '${preferredDate.month.toString().padLeft(2, '0')}/'
      '${preferredDate.year}';
}