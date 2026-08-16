/// Holds everything collected across the 7 onboarding steps.
/// Pass one instance down through the flow and read it on the summary screen.
class OnboardingData {
  // Step 2 — Personal info
  String fullName = '';
  String age = '';
  String? gender;
  String height = '';
  String weight = '';
  Set<String> goals = {};

  // Step 3 — Lifestyle
  String? activityLevel;
  String? sleepHours;
  String? waterIntake;

  // Step 4 — Health information
  Set<String> healthConditions = {};
  bool? pregnantOrBreastfeeding;

  // Step 5 — Food preferences
  String? dietType;
  Set<String> allergies = {};
  Set<String> dislikedFoods = {};

  // Step 6 — Personalize AI
  Set<String> nutritionFocus = {};
  Map<String, bool> productAlerts = {
    'Alert me if a product contains my allergens': true,
    'Warn me about high sugar products': true,
    'Warn me about high sodium': true,
    'Warn me about ultra-processed foods': true,
    'Suggest healthier alternatives automatically': true,
  };
  Map<String, bool> aiFeatures = {
    'Personalized recipes': true,
    'Smart shopping suggestions': true,
    'Pantry expiry reminders': true,
    'Weekly nutrition insights': true,
  };
}
