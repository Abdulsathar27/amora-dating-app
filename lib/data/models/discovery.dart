import 'package:equatable/equatable.dart';

import 'match.dart';

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

  factory SwipeResult.fromJson(Map<String, dynamic> json) => SwipeResult(
        isMatch: json['is_match'] as bool? ?? false,
        match: json['match'] == null ? null : Match.fromJson(json['match'] as Map<String, dynamic>),
      );
}

/// Who should appear in the deck.
enum InterestedIn {
  men('men', 'Men'),
  women('women', 'Women'),
  everyone('everyone', 'Everyone');

  const InterestedIn(this.value, this.label);
  final String value;
  final String label;

  static InterestedIn fromValue(String? v) =>
      values.firstWhere((e) => e.value == v, orElse: () => InterestedIn.everyone);
}

class DiscoveryPreferences extends Equatable {
  const DiscoveryPreferences({
    this.minAge = 21,
    this.maxAge = 35,
    this.maxDistanceKm = 30,
    this.interestedIn = InterestedIn.everyone,
    this.verifiedOnly = false,
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final InterestedIn interestedIn;
  final bool verifiedOnly;

  factory DiscoveryPreferences.fromJson(Map<String, dynamic> json) => DiscoveryPreferences(
        minAge: (json['min_age'] as num?)?.toInt() ?? 21,
        maxAge: (json['max_age'] as num?)?.toInt() ?? 35,
        maxDistanceKm: (json['max_distance_km'] as num?)?.toInt() ?? 30,
        interestedIn: InterestedIn.fromValue(json['interested_in'] as String?),
        verifiedOnly: json['verified_only'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'min_age': minAge,
        'max_age': maxAge,
        'max_distance_km': maxDistanceKm,
        'interested_in': interestedIn.value,
        'verified_only': verifiedOnly,
      };

  DiscoveryPreferences copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    InterestedIn? interestedIn,
    bool? verifiedOnly,
  }) =>
      DiscoveryPreferences(
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        interestedIn: interestedIn ?? this.interestedIn,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      );

  @override
  List<Object?> get props => [minAge, maxAge, maxDistanceKm, interestedIn, verifiedOnly];
}
