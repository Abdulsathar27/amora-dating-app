import 'package:equatable/equatable.dart';

/// What the person is hoping for ("What are you hoping for?" in profile creation).
enum RelationshipIntent {
  lifePartner('life_partner', 'A life partner', 'Ready for something lasting', 'Long-term', 'Life partner'),
  relationship('relationship', 'A real relationship', 'Open to seeing where it goes', 'Relationship', 'Relationship'),
  newConnections('new_connections', 'New connections', 'Dates, friends, good company', 'New connections', 'New connections'),
  figuringOut('figuring_out', 'Still figuring it out', 'And that’s completely fine', 'Figuring it out', 'Figuring it out');

  const RelationshipIntent(this.value, this.label, this.description, this.tag, this.filterLabel);

  final String value;
  final String label;
  final String description;

  /// Short blush tag shown on the profile card.
  final String tag;

  /// Label in Discovery filters.
  final String filterLabel;

  static RelationshipIntent fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => RelationshipIntent.figuringOut);
}

enum Gender {
  woman('woman', 'Woman'),
  man('man', 'Man'),
  nonBinary('non_binary', 'Non-binary'),
  selfDescribe('self_describe', 'Prefer to self-describe');

  const Gender(this.value, this.label);
  final String value;
  final String label;

  static Gender fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => Gender.nonBinary);
}

enum PhotoReview {
  approved('approved', 'Approved'),
  inReview('in_review', 'In review'),
  rejected('rejected', 'Not approved');

  const PhotoReview(this.value, this.label);
  final String value;
  final String label;

  static PhotoReview fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => PhotoReview.inReview);
}

/// Hinge-style question + answer.
class ProfilePrompt extends Equatable {
  const ProfilePrompt({required this.question, required this.answer});

  final String question;
  final String answer;

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) => ProfilePrompt(question: json['question'] as String, answer: json['answer'] as String);

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};

  @override
  List<Object?> get props => [question, answer];
}

/// Short spoken intro, e.g. “The small thing that made me smile today…”.
class VoiceIntro extends Equatable {
  const VoiceIntro({required this.prompt, required this.seconds, this.url});

  final String prompt;
  final int seconds;
  final String? url;

  String get durationLabel => '0:${seconds.toString().padLeft(2, '0')}';

  factory VoiceIntro.fromJson(Map<String, dynamic> json) =>
      VoiceIntro(prompt: json['prompt'] as String, seconds: (json['seconds'] as num).toInt(), url: json['url'] as String?);

  Map<String, dynamic> toJson() => {'prompt': prompt, 'seconds': seconds, 'url': url};

  @override
  List<Object?> get props => [prompt, seconds, url];
}

/// One "Homebody ↔ Adventurer" scale. [value] is 0..1.
class PersonalityTrait extends Equatable {
  const PersonalityTrait({required this.left, required this.right, required this.value});

  final String left;
  final String right;
  final double value;

  factory PersonalityTrait.fromJson(Map<String, dynamic> json) =>
      PersonalityTrait(left: json['left'] as String, right: json['right'] as String, value: (json['value'] as num).toDouble());

  @override
  List<Object?> get props => [left, right, value];
}

/// "On repeat" music entry.
class Song extends Equatable {
  const Song({required this.title, required this.note});

  final String title;
  final String note;

  factory Song.fromJson(Map<String, dynamic> json) => Song(title: json['title'] as String, note: json['note'] as String);

  @override
  List<Object?> get props => [title, note];
}

/// Lifestyle keys used across the card and full profile.
class Lifestyle {
  Lifestyle._();
  static const sleep = 'sleep', drinks = 'drinks', diet = 'diet', exercise = 'exercise', kids = 'kids', smoking = 'smoking';
  static const labels = {sleep: 'Sleep', drinks: 'Drinks', diet: 'Diet', exercise: 'Exercise', kids: 'Kids', smoking: 'Smoking'};
}

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.age,
    this.bio = '',
    this.quote,
    this.gender = Gender.nonBinary,
    this.intent = RelationshipIntent.figuringOut,
    this.jobTitle,
    this.city,
    this.distanceKm,
    this.isVerified = false,
    this.verifiedAt,
    this.compatibility,
    this.photos = const [],
    this.photoReviews = const [],
    this.prompts = const [],
    this.interests = const [],
    this.activities = const [],
    this.voice,
    this.videoThumb,
    this.lifestyle = const {},
    this.personality = const [],
    this.onRepeat = const [],
    this.relationshipGoal,
    this.starters = const [],
  });

  final String id;
  final String name;
  final int age;
  final String bio;

  /// Italic one-liner on the discovery card.
  final String? quote;
  final Gender gender;
  final RelationshipIntent intent;
  final String? jobTitle;
  final String? city;
  final double? distanceKm;
  final bool isVerified;
  final DateTime? verifiedAt;

  /// e.g. "In tune" chip on the card.
  final String? compatibility;
  final List<String> photos;

  /// Only present for your own profile (Manage photos).
  final List<PhotoReview> photoReviews;
  final List<ProfilePrompt> prompts;
  final List<String> interests;
  final List<String> activities;
  final VoiceIntro? voice;
  final String? videoThumb;
  final Map<String, String> lifestyle;
  final List<PersonalityTrait> personality;
  final List<Song> onRepeat;
  final String? relationshipGoal;
  final List<String> starters;

  String? get mainPhoto => photos.isEmpty ? null : photos.first;
  String get distanceLabel => distanceKm == null ? 'Nearby' : 'About ${distanceKm!.round()} km away';

  factory Profile.fromJson(Map<String, dynamic> json) {
    List<String> strings(String k) => (json[k] as List? ?? const []).map((e) => e.toString()).toList();
    List<T> objects<T>(String k, T Function(Map<String, dynamic>) f) => (json[k] as List? ?? const []).map((e) => f(e as Map<String, dynamic>)).toList();
    return Profile(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 18,
      bio: json['bio'] as String? ?? '',
      quote: json['quote'] as String?,
      gender: Gender.fromValue(json['gender'] as String?),
      intent: RelationshipIntent.fromValue(json['intent'] as String?),
      jobTitle: json['job_title'] as String?,
      city: json['city'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] == null ? null : DateTime.parse(json['verified_at'] as String),
      compatibility: json['compatibility'] as String?,
      photos: strings('photos'),
      photoReviews: strings('photo_reviews').map(PhotoReview.fromValue).toList(),
      prompts: objects('prompts', ProfilePrompt.fromJson),
      interests: strings('interests'),
      activities: strings('activities'),
      voice: json['voice'] == null ? null : VoiceIntro.fromJson(json['voice'] as Map<String, dynamic>),
      videoThumb: json['video_thumb'] as String?,
      lifestyle: (json['lifestyle'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      personality: objects('personality', PersonalityTrait.fromJson),
      onRepeat: objects('on_repeat', Song.fromJson),
      relationshipGoal: json['relationship_goal'] as String?,
      starters: strings('starters'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    age,
    bio,
    quote,
    gender,
    intent,
    jobTitle,
    city,
    distanceKm,
    isVerified,
    verifiedAt,
    compatibility,
    photos,
    photoReviews,
    prompts,
    interests,
    activities,
    voice,
    videoThumb,
    lifestyle,
    personality,
    onRepeat,
    relationshipGoal,
    starters,
  ];
}
