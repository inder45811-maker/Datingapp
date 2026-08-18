class UserProfile {
  final String id;
  final String displayName;
  final DateTime birthdate;
  final String bio;
  final String gender;
  final List<String> desires;
  final List<String> photos;
  final List<String> privatePhotos;
  final double distanceMeters;
  final bool isCoupled;
  final String? partnerId;
  final String? partnerName;
  final List<String>? partnerPhotos;
  final bool isPremium;
  final bool isIncognito;
  final bool isAvailableSoon;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.birthdate,
    required this.bio,
    required this.gender,
    required this.desires,
    required this.photos,
    this.privatePhotos = const [],
    this.distanceMeters = 0.0,
    this.isCoupled = false,
    this.partnerId,
    this.partnerName,
    this.partnerPhotos,
    this.isPremium = false,
    this.isIncognito = false,
    this.isAvailableSoon = false,
  });

  factory UserProfile.fromRpcJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Anonymous',
      birthdate: DateTime.parse(json['birthdate'] as String),
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String? ?? 'other',
      desires: List<String>.from(json['desires'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      isCoupled: json['is_coupled'] as bool? ?? false,
      partnerId: json['partner_id'] as String?,
      partnerName: json['partner_name'] as String?,
      partnerPhotos: json['partner_photos'] != null
          ? List<String>.from(json['partner_photos'])
          : null,
      isPremium: json['is_premium'] as bool? ?? false,
      isIncognito: json['is_incognito'] as bool? ?? false,
      isAvailableSoon: json['is_available_soon'] as bool? ?? false,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Anonymous',
      birthdate: DateTime.parse(json['birthdate'] as String),
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String? ?? 'other',
      desires: List<String>.from(json['desires'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      privatePhotos: List<String>.from(json['private_photos'] ?? []),
      isPremium: json['is_premium'] as bool? ?? false,
      isIncognito: json['is_incognito'] as bool? ?? false,
      partnerId: json['linked_partner_id'] as String?,
      isAvailableSoon: json['is_available_soon'] as bool? ?? false,
    );
  }

  int get age {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      years--;
    }
    return years;
  }
}
