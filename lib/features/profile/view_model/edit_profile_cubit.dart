import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';

/// Draft of "Edit profile" (about, prompt answer, interests).
class EditProfileState extends Equatable {
  const EditProfileState({required this.bio, required this.prompt, required this.interests, required this.original});

  static const maxBio = 200;

  final String bio;
  final ProfilePrompt? prompt;
  final List<String> interests;
  final Profile original;

  bool get isDirty => bio != original.bio || prompt != original.prompts.firstOrNull || interests.join() != original.interests.join();

  Map<String, dynamic> get changes => {
    'bio': bio.trim(),
    if (prompt != null) 'prompts': [prompt!.toJson(), ...original.prompts.skip(1).map((p) => p.toJson())],
    'interests': interests,
  };

  EditProfileState copyWith({String? bio, ProfilePrompt? prompt, List<String>? interests}) =>
      EditProfileState(bio: bio ?? this.bio, prompt: prompt ?? this.prompt, interests: interests ?? this.interests, original: original);

  @override
  List<Object?> get props => [bio, prompt, interests, original];
}

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(Profile p) : super(EditProfileState(bio: p.bio, prompt: p.prompts.firstOrNull, interests: p.interests, original: p));

  void bioChanged(String v) => emit(state.copyWith(bio: v));

  void promptAnswerChanged(String v) {
    final p = state.prompt;
    if (p != null) emit(state.copyWith(prompt: ProfilePrompt(question: p.question, answer: v)));
  }

  void interestToggled(String i) {
    final list = List<String>.of(state.interests);
    list.contains(i) ? list.remove(i) : list.add(i);
    emit(state.copyWith(interests: list));
  }
}

/// Draft of "What you're looking for".
class RelationshipPrefsState extends Equatable {
  const RelationshipPrefsState({required this.intent, required this.interestedIn, required this.kids, required this.smoking, required this.distanceKm});

  final RelationshipIntent intent;
  final InterestedIn interestedIn;
  final String kids;
  final String smoking;
  final int distanceKm;

  RelationshipPrefsState copyWith({RelationshipIntent? intent, InterestedIn? interestedIn, String? kids, String? smoking, int? distanceKm}) =>
      RelationshipPrefsState(
        intent: intent ?? this.intent,
        interestedIn: interestedIn ?? this.interestedIn,
        kids: kids ?? this.kids,
        smoking: smoking ?? this.smoking,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  @override
  List<Object?> get props => [intent, interestedIn, kids, smoking, distanceKm];
}

class RelationshipPrefsCubit extends Cubit<RelationshipPrefsState> {
  RelationshipPrefsCubit({required Profile profile, required DiscoveryPreferences prefs})
    : super(
        RelationshipPrefsState(
          intent: profile.intent,
          interestedIn: prefs.interestedIn,
          kids: profile.lifestyle[Lifestyle.kids] ?? 'Open to kids',
          smoking: profile.lifestyle[Lifestyle.smoking] ?? 'Prefer not',
          distanceKm: prefs.maxDistanceKm,
        ),
      );

  static const kidsOptions = ['Open to kids', 'Want kids', 'Don’t want kids', 'Have kids'];
  static const smokingOptions = ['Prefer not', 'Fine with it', 'Never'];
  static const distanceOptions = [5, 10, 15, 30, 50, 100];

  void intentSelected(RelationshipIntent v) => emit(state.copyWith(intent: v));
  void interestedInSelected(InterestedIn v) => emit(state.copyWith(interestedIn: v));
  void kidsChanged(String v) => emit(state.copyWith(kids: v));
  void smokingChanged(String v) => emit(state.copyWith(smoking: v));
  void distanceChanged(int v) => emit(state.copyWith(distanceKm: v));
}
