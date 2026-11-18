import 'package:equatable/equatable.dart';

import 'match.dart';
import 'profile.dart';

enum SwipeAction {
  pass('pass'),
  like('like'),
  superLike('super_like');

  const SwipeAction(this.value);
  final String value;
}

class SwipeResult {
  const SwipeResult({required this.isMatch, this.match});

  final bool isMatch;
  final Match? match;

  factory SwipeResult.fromJson(Map<String, dynamic> json) =>
      SwipeResult(isMatch: json['is_match'] as bool? ?? false, match: json['match'] == null ? null : Match.fromJson(json['match'] as Map<String, dynamic>));
}

/// "Who would you like to meet?"
enum InterestedIn {
  women('women', 'Women'),
  men('men', 'Men'),
  everyone('everyone', 'Everyone');

  const InterestedIn(this.value, this.label);
  final String value;
  final String label;

  static InterestedIn fromValue(String? v) => values.firstWhere((e) => e.value == v, orElse: () => InterestedIn.everyone);
}

class DiscoveryPreferences extends Equatable {
  const DiscoveryPreferences({
    this.minAge = 25,
    this.maxAge = 34,
    this.maxDistanceKm = 15,
    this.interestedIn = InterestedIn.everyone,
    this.lookingFor = const {RelationshipIntent.lifePartner, RelationshipIntent.relationship},
    this.verifiedOnly = true,
    this.hasVoiceIntro = false,
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final InterestedIn interestedIn;
  final Set<RelationshipIntent> lookingFor;
  final bool verifiedOnly;
  final bool hasVoiceIntro;

  factory DiscoveryPreferences.fromJson(Map<String, dynamic> json) => DiscoveryPreferences(
    minAge: (json['min_age'] as num?)?.toInt() ?? 25,
    maxAge: (json['max_age'] as num?)?.toInt() ?? 34,
    maxDistanceKm: (json['max_distance_km'] as num?)?.toInt() ?? 15,
    interestedIn: InterestedIn.fromValue(json['interested_in'] as String?),
    lookingFor: (json['looking_for'] as List? ?? const []).map((e) => RelationshipIntent.fromValue(e as String)).toSet(),
    verifiedOnly: json['verified_only'] as bool? ?? false,
    hasVoiceIntro: json['has_voice_intro'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'min_age': minAge,
    'max_age': maxAge,
    'max_distance_km': maxDistanceKm,
    'interested_in': interestedIn.value,
    'looking_for': lookingFor.map((e) => e.value).toList(),
    'verified_only': verifiedOnly,
    'has_voice_intro': hasVoiceIntro,
  };

  DiscoveryPreferences copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    InterestedIn? interestedIn,
    Set<RelationshipIntent>? lookingFor,
    bool? verifiedOnly,
    bool? hasVoiceIntro,
  }) => DiscoveryPreferences(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    interestedIn: interestedIn ?? this.interestedIn,
    lookingFor: lookingFor ?? this.lookingFor,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    hasVoiceIntro: hasVoiceIntro ?? this.hasVoiceIntro,
  );

  @override
  List<Object?> get props => [minAge, maxAge, maxDistanceKm, interestedIn, lookingFor, verifiedOnly, hasVoiceIntro];
}
