// lib/models/review_model.dart
// Pure Dart — zero Firebase or Flutter imports

class Review {
  final String? id;
  final String clientId;
  final String technicianId;
  final String requestId;
  final int rating;        // 1–5
  final String comment;
  final DateTime createdAt;

  const Review({
    this.id,
    required this.clientId,
    required this.technicianId,
    required this.requestId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      clientId: map['clientId'] ?? '',
      technicianId: map['technicianId'] ?? '',
      requestId: map['requestId'] ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'technicianId': technicianId,
        'requestId': requestId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };
}
