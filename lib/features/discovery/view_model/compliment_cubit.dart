import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/profile.dart';
import '../../../core/constants/app_strings.dart';

class ComplimentState extends Equatable {
  const ComplimentState({this.text = '', this.version = 0});

  static const maxLength = 140;

  final String text;

  /// Bumped when a suggestion chip replaces the text, so the field rebuilds with it.
  final int version;

  bool get canSend => text.trim().length >= 3 && text.length <= maxLength;
  String get counter => '${text.length} / $maxLength';

  @override
  List<Object?> get props => [text, version];
}

/// "Send Maya a compliment": suggestion chips + a 140-character note.
class ComplimentCubit extends Cubit<ComplimentState> {
  ComplimentCubit() : super(const ComplimentState());

  void changed(String v) => emit(ComplimentState(text: v, version: state.version));

  void suggestionPicked(String s) {
    final text = s.length > ComplimentState.maxLength ? s.substring(0, ComplimentState.maxLength) : s;
    emit(ComplimentState(text: text, version: state.version + 1));
  }

  /// Suggestions built from what the person actually shared.
  static List<String> suggestionsFor(Profile p) => [
    if (p.voice != null) AppStrings.complimentVoice,
    if (p.interests.length > 1) AppStrings.complimentTaste(p.interests[1].toLowerCase()),
    AppStrings.complimentSmile,
    if (p.interests.isNotEmpty) AppStrings.complimentTellMore(p.interests.first),
  ];
}
