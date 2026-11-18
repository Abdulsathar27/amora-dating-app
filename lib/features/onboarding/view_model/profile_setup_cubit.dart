import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../../../data/repositories/profile_repository.dart';

const kInterestOptions = [
  'Bookshops',
  'Hiking',
  'Ceramics',
  'Live music',
  'Cooking',
  'Indie folk',
  'Film photography',
  'Yoga',
  'Board games',
  'Road trips',
  'Museums',
  'Baking',
  'Dogs',
  'Cycling',
  'Poetry',
];

const kVoicePrompt = '“The small thing that made me smile today…”';

/// Placeholder library standing in for the photo picker until uploads exist.
const kSamplePhotos = ['assets/images/maya.jpg', 'assets/images/dunes.jpg', 'assets/images/cafe.jpg', 'assets/images/sea.jpg'];

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.name = 'Maya',
    this.gender = Gender.woman,
    this.interestedIn = InterestedIn.men,
    this.photos = const ['assets/images/maya.jpg', 'assets/images/dunes.jpg'],
    this.intent = RelationshipIntent.lifePartner,
    this.interests = const {'Bookshops', 'Ceramics', 'Indie folk'},
    this.voiceSeconds = 0,
    this.isRecording = false,
    this.showDistance = true,
    this.isSubmitting = false,
    this.error,
  });

  static const maxInterests = 5;
  static const maxVoice = 15;

  final String name;
  final Gender gender;
  final InterestedIn interestedIn;
  final List<String> photos;
  final RelationshipIntent intent;
  final Set<String> interests;
  final int voiceSeconds;
  final bool isRecording;
  final bool showDistance;
  final bool isSubmitting;
  final String? error;

  bool get nameValid => name.trim().length >= 2;
  bool get hasPhoto => photos.isNotEmpty;
  bool get hasVoice => voiceSeconds > 0 && !isRecording;
  String get voiceLabel => '0:${voiceSeconds.toString().padLeft(2, '0')} / 0:$maxVoice';

  ProfileSetupState copyWith({
    String? name,
    Gender? gender,
    InterestedIn? interestedIn,
    List<String>? photos,
    RelationshipIntent? intent,
    Set<String>? interests,
    int? voiceSeconds,
    bool? isRecording,
    bool? showDistance,
    bool? isSubmitting,
    String? Function()? error,
  }) => ProfileSetupState(
    name: name ?? this.name,
    gender: gender ?? this.gender,
    interestedIn: interestedIn ?? this.interestedIn,
    photos: photos ?? this.photos,
    intent: intent ?? this.intent,
    interests: interests ?? this.interests,
    voiceSeconds: voiceSeconds ?? this.voiceSeconds,
    isRecording: isRecording ?? this.isRecording,
    showDistance: showDistance ?? this.showDistance,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [name, gender, interestedIn, photos, intent, interests, voiceSeconds, isRecording, showDistance, isSubmitting, error];
}

/// "Create your profile": one small question per screen, saved once at the end.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(this._profiles, this._discovery, {String? initialName})
    : super(initialName == null || initialName.isEmpty ? const ProfileSetupState() : ProfileSetupState(name: initialName));

  final ProfileRepository _profiles;
  final DiscoveryRepository _discovery;
  Timer? _recorder;

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void genderSelected(Gender g) => emit(state.copyWith(gender: g));
  void interestedInSelected(InterestedIn v) => emit(state.copyWith(interestedIn: v));
  void intentSelected(RelationshipIntent v) => emit(state.copyWith(intent: v));
  void showDistanceChanged(bool v) => emit(state.copyWith(showDistance: v));

  void addPhoto() {
    if (state.photos.length >= 6) return;
    final next = kSamplePhotos.firstWhere((p) => !state.photos.contains(p), orElse: () => kSamplePhotos.last);
    emit(state.copyWith(photos: [...state.photos, next]));
  }

  void removePhoto(int index) => emit(state.copyWith(photos: List.of(state.photos)..removeAt(index)));

  void interestToggled(String i) {
    final next = Set<String>.of(state.interests);
    if (next.contains(i)) {
      next.remove(i);
    } else if (next.length < ProfileSetupState.maxInterests) {
      next.add(i);
    }
    emit(state.copyWith(interests: next));
  }

  /// Simulated recorder (counts up to 15s). Swap for the `record` plugin when audio upload exists.
  void toggleRecording() {
    if (state.isRecording) {
      _recorder?.cancel();
      emit(state.copyWith(isRecording: false));
      return;
    }
    emit(state.copyWith(isRecording: true, voiceSeconds: 0));
    _recorder = Timer.periodic(const Duration(seconds: 1), (t) {
      final s = state.voiceSeconds + 1;
      if (s >= ProfileSetupState.maxVoice) {
        t.cancel();
        emit(state.copyWith(voiceSeconds: ProfileSetupState.maxVoice, isRecording: false));
      } else {
        emit(state.copyWith(voiceSeconds: s));
      }
    });
  }

  /// Saves the whole profile. Returns true on success.
  Future<bool> submit() async {
    emit(state.copyWith(isSubmitting: true, error: () => null));
    try {
      await _profiles.updateMyProfile({
        'name': state.name.trim(),
        'gender': state.gender.value,
        'intent': state.intent.value,
        'photos': state.photos,
        'interests': state.interests.toList(),
        if (state.hasVoice) 'voice': {'prompt': kVoicePrompt, 'seconds': state.voiceSeconds},
        'complete_onboarding': true,
      });
      final prefs = await _discovery.preferences();
      await _discovery.savePreferences(prefs.copyWith(interestedIn: state.interestedIn));
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: () => e.message));
      return false;
    }
  }

  @override
  Future<void> close() {
    _recorder?.cancel();
    return super.close();
  }
}
