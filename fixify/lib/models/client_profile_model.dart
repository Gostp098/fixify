
enum Gender { male, female, preferNotToSay }

enum ContactMethod { sms, email, call, inApp }

class ClientProfile {
  final String uid;
  final String address;
  final String city;
  final Gender gender;
  final ContactMethod preferredContact;
  final String? alternativePhone;
  final String? photoUrl;
  final bool profileComplete;

  const ClientProfile({
    required this.uid,
    required this.address,
    required this.city,
    required this.gender,
    required this.preferredContact,
    this.alternativePhone,
    this.photoUrl,
    this.profileComplete = false,
  });

  // From Firestore map
  factory ClientProfile.fromMap(String uid, Map<String, dynamic> map) {
    return ClientProfile(
      uid: uid,
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      gender: Gender.values.firstWhere(
        (g) => g.name == map['gender'],
        orElse: () => Gender.preferNotToSay,
      ),
      preferredContact: ContactMethod.values.firstWhere(
        (c) => c.name == map['preferredContact'],
        orElse: () => ContactMethod.inApp,
      ),
      alternativePhone: map['alternativePhone'],
      photoUrl: map['photoUrl'],
      profileComplete: map['profileComplete'] ?? false,
    );
  }

  // To Firestore map
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'gender': gender.name,
      'preferredContact': preferredContact.name,
      'alternativePhone': alternativePhone,
      'photoUrl': photoUrl,
      'profileComplete': profileComplete,
    };
  }

  ClientProfile copyWith({
    String? address,
    String? city,
    Gender? gender,
    ContactMethod? preferredContact,
    String? alternativePhone,
    String? photoUrl,
    bool? profileComplete,
  }) {
    return ClientProfile(
      uid: uid,
      address: address ?? this.address,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      preferredContact: preferredContact ?? this.preferredContact,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      photoUrl: photoUrl ?? this.photoUrl,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  // Display helpers
  String get genderLabel {
    switch (gender) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.preferNotToSay: return 'Prefer not to say';
    }
  }

  String get contactLabel {
    switch (preferredContact) {
      case ContactMethod.sms: return 'SMS';
      case ContactMethod.email: return 'Email';
      case ContactMethod.call: return 'Call';
      case ContactMethod.inApp: return 'In-app';
    }
  }
}
