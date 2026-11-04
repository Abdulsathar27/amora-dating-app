import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/profile.dart';

/// Draft copy of the profile while editing; ProfileBloc persists it.
class EditProfileState extends Equatable {
  const EditProfileState(this.draft, this.original);

  final Profile draft;
  final Profile original;

  bool get isDirty => draft != original;

  Map<String, dynamic> get changes {
    final a = draft.toJson();
    final b = original.toJson();
    return {for (final k in a.keys) if (a[k].toString() != b[k].toString()) k: a[k]};
  }

  @override
  List<Object?> get props => [draft, original];
}

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(Profile profile) : super(EditProfileState(profile, profile));

  void _set(Profile p) => emit(EditProfileState(p, state.original));

  void bioChanged(String v) => _set(state.draft.copyWith(bio: v));
  void jobChanged(String v) => _set(state.draft.copyWith(jobTitle: v));
  void schoolChanged(String v) => _set(state.draft.copyWith(school: v));
  void cityChanged(String v) => _set(state.draft.copyWith(city: v));
  void intentChanged(RelationshipIntent v) => _set(state.draft.copyWith(intent: v));

  void interestToggled(String i) {
    final list = List<String>.of(state.draft.interests);
    list.contains(i) ? list.remove(i) : list.add(i);
    _set(state.draft.copyWith(interests: list));
  }

  void promptAnswerChanged(int index, String answer) {
    final prompts = List<ProfilePrompt>.of(state.draft.prompts);
    prompts[index] = ProfilePrompt(question: prompts[index].question, answer: answer);
    _set(state.draft.copyWith(prompts: prompts));
  }

  void promptAdded(String question) {
    if (state.draft.prompts.length >= 3) return;
    _set(state.draft.copyWith(prompts: [...state.draft.prompts, ProfilePrompt(question: question, answer: '')]));
  }

  void promptRemoved(int index) {
    final prompts = List<ProfilePrompt>.of(state.draft.prompts)..removeAt(index);
    _set(state.draft.copyWith(prompts: prompts));
  }

  void photoAdded(String url) {
    if (url.trim().isEmpty || state.draft.photos.length >= 6) return;
    _set(state.draft.copyWith(photos: [...state.draft.photos, url.trim()]));
  }

  void photoRemoved(int index) {
    final photos = List<String>.of(state.draft.photos)..removeAt(index);
    _set(state.draft.copyWith(photos: photos));
  }
}
