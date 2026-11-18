import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/match.dart';
import '../../../data/repositories/match_repository.dart';

sealed class MatchesEvent extends Equatable {
  const MatchesEvent();
  @override
  List<Object?> get props => [];
}

class MatchesRequested extends MatchesEvent {
  const MatchesRequested();
}

class UnmatchRequested extends MatchesEvent {
  const UnmatchRequested(this.matchId);
  final String matchId;
  @override
  List<Object?> get props => [matchId];
}

/// Removes a match locally after the person was blocked.
class MatchRemoved extends MatchesEvent {
  const MatchRemoved(this.profileId);
  final String profileId;
  @override
  List<Object?> get props => [profileId];
}

enum MatchesStatus { loading, ready, failure }

class MatchesState extends Equatable {
  const MatchesState({this.status = MatchesStatus.loading, this.matches = const [], this.error});

  final MatchesStatus status;
  final List<Match> matches;
  final String? error;

  /// "Waiting for your hello": matched, nobody has written yet.
  List<Match> get newMatches => matches.where((m) => !m.hasConversation).toList();

  /// "Getting to know" / Messages list.
  List<Match> get conversations => matches.where((m) => m.hasConversation).toList();

  int get unreadTotal => matches.fold(0, (sum, m) => sum + m.unreadCount);

  Match? byId(String id) => matches.where((m) => m.id == id).firstOrNull;

  MatchesState copyWith({MatchesStatus? status, List<Match>? matches, String? Function()? error}) => MatchesState(
    status: status ?? this.status,
    matches: matches ?? this.matches,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, matches, error];
}

/// Feeds both the Matches tab and the Messages tab.
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  MatchesBloc(this._repo) : super(const MatchesState()) {
    on<MatchesRequested>(_onRequested);
    on<UnmatchRequested>(_onUnmatch);
    on<MatchRemoved>(
      (e, emit) => emit(state.copyWith(matches: state.matches.where((m) => m.profile.id != e.profileId).toList())),
    );
  }

  final MatchRepository _repo;

  Future<void> _onRequested(MatchesRequested e, Emitter<MatchesState> emit) async {
    try {
      emit(state.copyWith(status: MatchesStatus.ready, matches: await _repo.matches(), error: () => null));
    } on ApiException catch (err) {
      emit(
        state.copyWith(
          status: state.matches.isEmpty ? MatchesStatus.failure : MatchesStatus.ready,
          error: () => err.message,
        ),
      );
    }
  }

  Future<void> _onUnmatch(UnmatchRequested e, Emitter<MatchesState> emit) async {
    final before = state.matches;
    emit(state.copyWith(matches: before.where((m) => m.id != e.matchId).toList()));
    try {
      await _repo.unmatch(e.matchId);
    } on ApiException catch (err) {
      emit(state.copyWith(matches: before, error: () => err.message));
    }
  }
}
