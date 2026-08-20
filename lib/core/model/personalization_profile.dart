import '../../features/personalization/lib/onboarding/onboarding_data.dart';

/// DietCompass — PersonalizationProfile Model
///
/// Encapsulates the user's nutritional & AI personalization preferences
/// synchronized to and from MongoDB Atlas (`/api/personalization`).
class PersonalizationProfile {
  PersonalizationProfile({
    required this.id,
    required this.userId,
    this.fullName = '',
    this.age = '',
    this.gender,
    this.height = '',
    this.weight = '',
    this.goals = const {},
    this.activityLevel,
    this.sleepHours,
    this.waterIntake,
    this.healthConditions = const {},
    this.pregnantOrBreastfeeding,
    this.dietType,
    this.allergies = const {},
    this.dislikedFoods = const {},
    this.nutritionFocus = const {},
    this.productAlerts = const {},
    this.aiFeatures = const {},
    this.isCompleted = false,
  });

  final String id;
  final String userId;
  final String fullName;
  final String age;
  final String? gender;
  final String height;
  final String weight;
  final Set<String> goals;
  final String? activityLevel;
  final String? sleepHours;
  final String? waterIntake;
  final Set<String> healthConditions;
  final bool? pregnantOrBreastfeeding;
  final String? dietType;
  final Set<String> allergies;
  final Set<String> dislikedFoods;
  final Set<String> nutritionFocus;
  final Map<String, bool> productAlerts;
  final Map<String, bool> aiFeatures;
  final bool isCompleted;

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) {
    Map<String, bool> parseBoolMap(dynamic map) {
      if (map is Map) {
        return map.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return {};
    }

    Set<String> parseStringSet(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
      return {};
    }

    return PersonalizationProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String?,
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      goals: parseStringSet(json['goals']),
      activityLevel: json['activityLevel'] as String?,
      sleepHours: json['sleepHours'] as String?,
      waterIntake: json['waterIntake'] as String?,
      healthConditions: parseStringSet(json['healthConditions']),
      pregnantOrBreastfeeding: json['pregnantOrBreastfeeding'] as bool?,
      dietType: json['dietType'] as String?,
      allergies: parseStringSet(json['allergies']),
      dislikedFoods: parseStringSet(json['dislikedFoods']),
      nutritionFocus: parseStringSet(json['nutritionFocus']),
      productAlerts: parseBoolMap(json['productAlerts']),
      aiFeatures: parseBoolMap(json['aiFeatures']),
      isCompleted: json['isCompleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'age': age,
      if (gender != null) 'gender': gender,
      'height': height,
      'weight': weight,
      'goals': goals.toList(),
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (sleepHours != null) 'sleepHours': sleepHours,
      if (waterIntake != null) 'waterIntake': waterIntake,
      'healthConditions': healthConditions.toList(),
      if (pregnantOrBreastfeeding != null) 'pregnantOrBreastfeeding': pregnantOrBreastfeeding,
      if (dietType != null) 'dietType': dietType,
      'allergies': allergies.toList(),
      'dislikedFoods': dislikedFoods.toList(),
      'nutritionFocus': nutritionFocus.toList(),
      'productAlerts': productAlerts,
      'aiFeatures': aiFeatures,
      'isCompleted': isCompleted,
    };
  }

  /// Converts this profile into an [OnboardingData] instance for the UI flow.
  OnboardingData toOnboardingData() {
    final data = OnboardingData();
    data.fullName = fullName;
    data.age = age;
    data.gender = gender;
    data.height = height;
    data.weight = weight;
    data.goals = {...goals};
    data.activityLevel = activityLevel;
    data.sleepHours = sleepHours;
    data.waterIntake = waterIntake;
    data.healthConditions = {...healthConditions};
    data.pregnantOrBreastfeeding = pregnantOrBreastfeeding;
    data.dietType = dietType;
    data.allergies = {...allergies};
    data.dislikedFoods = {...dislikedFoods};
    data.nutritionFocus = {...nutritionFocus};
    if (productAlerts.isNotEmpty) {
      data.productAlerts = {...productAlerts};
    }
    if (aiFeatures.isNotEmpty) {
      data.aiFeatures = {...aiFeatures};
    }
    return data;
  }

  /// Creates a [PersonalizationProfile] from UI [OnboardingData].
  factory PersonalizationProfile.fromOnboardingData(
    OnboardingData data, {
    String id = '',
    String userId = '',
    bool isCompleted = true,
  }) {
    return PersonalizationProfile(
      id: id,
      userId: userId,
      fullName: data.fullName,
      age: data.age,
      gender: data.gender,
      height: data.height,
      weight: data.weight,
      goals: {...data.goals},
      activityLevel: data.activityLevel,
      sleepHours: data.sleepHours,
      waterIntake: data.waterIntake,
      healthConditions: {...data.healthConditions},
      pregnantOrBreastfeeding: data.pregnantOrBreastfeeding,
      dietType: data.dietType,
      allergies: {...data.allergies},
      dislikedFoods: {...data.dislikedFoods},
      nutritionFocus: {...data.nutritionFocus},
      productAlerts: {...data.productAlerts},
      aiFeatures: {...data.aiFeatures},
      isCompleted: isCompleted,
    );
  }
}
