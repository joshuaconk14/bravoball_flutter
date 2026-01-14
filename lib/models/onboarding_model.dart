/// Onboarding Data Model
/// Mirrors Swift OnboardingData and backend onboarding payload
class OnboardingData {
  final String email;
  final String username;
  final String password;
  final String primaryGoal;
  final String trainingExperience;
  final String position;
  final String ageRange;
  final List<String> strengths;
  final List<String> areasToImprove;
  // Optional fields for backend compatibility
  final List<String> biggestChallenge;
  final List<String> playstyle;
  final List<String> trainingLocation;
  final List<String> availableEquipment;
  final String dailyTrainingTime;
  final String weeklyTrainingDays;

  OnboardingData({
    required this.email,
    required this.username,
    required this.password,
    required this.primaryGoal,
    required this.trainingExperience,
    required this.position,
    required this.ageRange,
    required this.strengths,
    required this.areasToImprove,
    this.biggestChallenge = const [],
    this.playstyle = const [],
    this.trainingLocation = const [],
    this.availableEquipment = const ["Soccer ball"],
    this.dailyTrainingTime = "30",
    this.weeklyTrainingDays = "moderate",
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'primaryGoal': primaryGoal,
      'trainingExperience': trainingExperience,
      'position': position,
      'ageRange': ageRange,
      'strengths': strengths,
      'areasToImprove': areasToImprove,
      'biggestChallenge': biggestChallenge,
      'playstyle': playstyle,
      'trainingLocation': trainingLocation,
      'availableEquipment': availableEquipment,
      'dailyTrainingTime': dailyTrainingTime,
      'weeklyTrainingDays': weeklyTrainingDays,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      primaryGoal: json['primaryGoal'] ?? '',
      trainingExperience: json['trainingExperience'] ?? '',
      position: json['position'] ?? '',
      ageRange: json['ageRange'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasToImprove: List<String>.from(json['areasToImprove'] ?? []),
      biggestChallenge: List<String>.from(json['biggestChallenge'] ?? []),
      playstyle: List<String>.from(json['playstyle'] ?? []),
      trainingLocation: List<String>.from(json['trainingLocation'] ?? []),
      availableEquipment: List<String>.from(json['availableEquipment'] ?? ["Soccer ball"]),
      dailyTrainingTime: json['dailyTrainingTime'] ?? "30",
      weeklyTrainingDays: json['weeklyTrainingDays'] ?? "moderate",
    );
  }
} 