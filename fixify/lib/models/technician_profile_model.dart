// lib/models/technician_profile_model.dart
// Pure Dart — no Flutter, no Firebase imports

class TechnicianProfile {
  final String uid;
  final String headline;
  final String trade;
  final double hourlyRate;
  final int yearsOfExperience;
  final int serviceRadius;
  final String bio;
  final String? photoUrl;
  final String? licenseUrl;
  final bool isOnline;
  final bool profileComplete;
  final double rating;
  final int totalReviews;

  const TechnicianProfile({
    required this.uid,
    required this.headline,
    required this.trade,
    required this.hourlyRate,
    required this.yearsOfExperience,
    required this.serviceRadius,
    required this.bio,
    this.photoUrl,
    this.licenseUrl,
    this.isOnline = false,
    this.profileComplete = false,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  factory TechnicianProfile.fromMap(String uid, Map<String, dynamic> map) {
    return TechnicianProfile(
      uid: uid,
      headline: map['headline'] ?? '',
      trade: map['trade'] ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toInt() ?? 0,
      serviceRadius: (map['serviceRadius'] as num?)?.toInt() ?? 0,
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'],
      licenseUrl: map['licenseUrl'],
      isOnline: map['isOnline'] ?? false,
      profileComplete: map['profileComplete'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'headline': headline,
      'trade': trade,
      'hourlyRate': hourlyRate,
      'yearsOfExperience': yearsOfExperience,
      'serviceRadius': serviceRadius,
      'bio': bio,
      'photoUrl': photoUrl,
      'licenseUrl': licenseUrl,
      'isOnline': isOnline,
      'profileComplete': profileComplete,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }

  TechnicianProfile copyWith({
    String? headline,
    String? trade,
    double? hourlyRate,
    int? yearsOfExperience,
    int? serviceRadius,
    String? bio,
    String? photoUrl,
    String? licenseUrl,
    bool? isOnline,
    bool? profileComplete,
    double? rating,
    int? totalReviews,
  }) {
    return TechnicianProfile(
      uid: uid,
      headline: headline ?? this.headline,
      trade: trade ?? this.trade,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      isOnline: isOnline ?? this.isOnline,
      profileComplete: profileComplete ?? this.profileComplete,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
