import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/profile_repository.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileSaved extends ProfileEvent {
  const ProfileSaved(this.changes);
  final Map<String, dynamic> changes;
  @override
  List<Object?> get props => [changes];
}

class VoiceIntroRemoved extends ProfileEvent {
  const VoiceIntroRemoved();
}

enum ProfileStatus { loading, ready, saving, failure }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.loading, this.profile, this.error, this.savedAt});

  final ProfileStatus status;
  final Profile? profile;
  final String? error;

  /// Changes after each successful save so views can react once.
  final DateTime? savedAt;

  /// "80% complete" ring on My Profile.
  double get completeness {
    final p = profile;
    if (p == null) return 0;
    final checks = [
      p.photos.length >= 3,
      p.bio.length >= 10,
      p.prompts.isNotEmpty,
      p.interests.length >= 3,
      p.voice != null,
    ];
    return checks.where((c) => c).length / checks.length;
  }

  ProfileState copyWith({ProfileStatus? status, Profile? profile, String? Function()? error, DateTime? savedAt}) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        error: error != null ? error() : this.error,
        savedAt: savedAt ?? this.savedAt,
      );

  @override
  List<Object?> get props => [status, profile, error, savedAt];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repo) : super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileSaved>((e, emit) => _save(emit, e.changes));
    on<VoiceIntroRemoved>((e, emit) => _save(emit, {'voice': null}));
  }

  final ProfileRepository _repo;

  Future<void> _onRequested(ProfileRequested e, Emitter<ProfileState> emit) async {
    try {
      emit(state.copyWith(status: ProfileStatus.ready, profile: await _repo.myProfile(), error: () => null));
    } on ApiException catch (err) {
      emit(state.copyWith(status: ProfileStatus.failure, error: () => err.message));
    }
  }

  Future<void> _save(Emitter<ProfileState> emit, Map<String, dynamic> changes) async {
    emit(state.copyWith(status: ProfileStatus.saving, error: () => null));
    try {
      final p = await _repo.updateMyProfile(changes);
      emit(state.copyWith(status: ProfileStatus.ready, profile: p, savedAt: DateTime.now()));
    } on ApiException catch (err) {
      emit(state.copyWith(status: ProfileStatus.ready, error: () => err.message));
    }
  }
}
