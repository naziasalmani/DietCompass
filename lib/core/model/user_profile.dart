/// DietCompass — UserProfile Model
///
/// Comprehensive model representing the user's synchronized profile
/// from MongoDB Atlas (`/api/profile`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.accountType,
    this.avatarUrl = '',
    this.badgeLabel = 'Healthy Explorer',
    this.dateOfBirth = '',
    this.gender = '',
    this.country = 'India',
    this.city = '',
    this.address = '',
    this.occupation = '',
    this.dietType = 'Vegetarian',
    this.height = '',
    this.weight = '',
    this.healthScore = 85,
    this.streakDays = 1,
    this.createdAt,
    this.isPersonalizationComplete = false,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String countryCode;
  final String accountType;
  final String avatarUrl;
  final String badgeLabel;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String city;
  final String address;
  final String occupation;
  final String dietType;
  final String height;
  final String weight;
  final int healthScore;
  final int streakDays;
  final DateTime? createdAt;
  final bool isPersonalizationComplete;

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    bool isPersonalizationComplete = false,
  }) {
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '+91',
      accountType: json['accountType'] as String? ?? 'individual',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      badgeLabel: json['badgeLabel'] as String? ?? 'Healthy Explorer',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      dietType: json['dietType'] as String? ?? 'Vegetarian',
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 85,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isPersonalizationComplete:
          isPersonalizationComplete ||
          (json['isPersonalizationComplete'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'countryCode': countryCode,
      'avatarUrl': avatarUrl,
      'badgeLabel': badgeLabel,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'country': country,
      'city': city,
      'address': address,
      'occupation': occupation,
      'dietType': dietType,
      'height': height,
      'weight': weight,
      'healthScore': healthScore,
      'streakDays': streakDays,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? countryCode,
    String? avatarUrl,
    String? badgeLabel,
    String? dateOfBirth,
    String? gender,
    String? country,
    String? city,
    String? address,
    String? occupation,
    String? dietType,
    String? height,
    String? weight,
    int? healthScore,
    int? streakDays,
    bool? isPersonalizationComplete,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username,
      email: email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      accountType: accountType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      dietType: dietType ?? this.dietType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      healthScore: healthScore ?? this.healthScore,
      streakDays: streakDays ?? this.streakDays,
      isPersonalizationComplete:
          isPersonalizationComplete ?? this.isPersonalizationComplete,
    );
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return email.split('@').first;
  }

  String get avatarInitial {
    final n = displayName;
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }
}
