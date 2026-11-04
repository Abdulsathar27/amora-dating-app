import 'package:equatable/equatable.dart';

/// What the person is looking for (Hinge / Aisle style "dating intention").
enum RelationshipIntent {
  longTerm('long_term', 'Long-term relationship'),
  marriage('marriage', 'Marriage'),
  shortTerm('short_term', 'Something casual'),
  figuringOut('figuring_out', 'Still figuring it out');

  const RelationshipIntent(this.value, this.label);
  final String value;
  final String label;

  static RelationshipIntent fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => RelationshipIntent.figuringOut);
}

enum Gender {
  man('man', 'Man'),
  woman('woman', 'Woman'),
  nonBinary('non_binary', 'Non-binary');

  const Gender(this.value, this.label);
  final String value;
  final String label;

  static Gender fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => Gender.nonBinary);
}

/// Hinge-style question + answer shown on the card.
class ProfilePrompt extends Equatable {
  const ProfilePrompt({required this.question, required this.answer});

  final String question;
  final String answer;

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) =>
      ProfilePrompt(question: json['question'] as String, answer: json['answer'] as String);

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};

  @override
  List<Object?> get props => [question, answer];
}

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.age,
    this.bio = '',
    this.gender = Gender.nonBinary,
    this.intent = RelationshipIntent.figuringOut,
    this.jobTitle,
    this.school,
    this.city,
    this.distanceKm,
    this.heightCm,
    this.isVerified = false,
    this.photos = const [],
    this.prompts = const [],
    this.interests = const [],
  });

  final String id;
  final String name;
  final int age;
  final String bio;
  final Gender gender;
  final RelationshipIntent intent;
  final String? jobTitle;
  final String? school;
  final String? city;
  final double? distanceKm;
  final int? heightCm;
  final bool isVerified;
  final List<String> photos;
  final List<ProfilePrompt> prompts;
  final List<String> interests;

  String? get mainPhoto => photos.isEmpty ? null : photos.first;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        age: (json['age'] as num?)?.toInt() ?? 18,
        bio: json['bio'] as String? ?? '',
        gender: Gender.fromValue(json['gender'] as String?),
        intent: RelationshipIntent.fromValue(json['intent'] as String?),
        jobTitle: json['job_title'] as String?,
        school: json['school'] as String?,
        city: json['city'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toInt(),
        isVerified: json['is_verified'] as bool? ?? false,
        photos: (json['photos'] as List? ?? const []).map((e) => e.toString()).toList(),
        prompts: (json['prompts'] as List? ?? const [])
            .map((e) => ProfilePrompt.fromJson(e as Map<String, dynamic>))
            .toList(),
        interests: (json['interests'] as List? ?? const []).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'bio': bio,
        'gender': gender.value,
        'intent': intent.value,
        'job_title': jobTitle,
        'school': school,
        'city': city,
        'distance_km': distanceKm,
        'height_cm': heightCm,
        'is_verified': isVerified,
        'photos': photos,
        'prompts': prompts.map((e) => e.toJson()).toList(),
        'interests': interests,
      };

  Profile copyWith({
    String? name,
    int? age,
    String? bio,
    Gender? gender,
    RelationshipIntent? intent,
    String? jobTitle,
    String? school,
    String? city,
    int? heightCm,
    List<String>? photos,
    List<ProfilePrompt>? prompts,
    List<String>? interests,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        bio: bio ?? this.bio,
        gender: gender ?? this.gender,
        intent: intent ?? this.intent,
        jobTitle: jobTitle ?? this.jobTitle,
        school: school ?? this.school,
        city: city ?? this.city,
        distanceKm: distanceKm,
        heightCm: heightCm ?? this.heightCm,
        isVerified: isVerified,
        photos: photos ?? this.photos,
        prompts: prompts ?? this.prompts,
        interests: interests ?? this.interests,
      );

  @override
  List<Object?> get props =>
      [id, name, age, bio, gender, intent, jobTitle, school, city, distanceKm, heightCm, isVerified, photos, prompts, interests];
}
