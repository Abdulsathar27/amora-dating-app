import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/match.dart';
import '../../../data/repositories/discovery_repository.dart';

sealed class LikesEvent extends Equatable {
  const LikesEvent();
  @override
  List<Object?> get props => [];
}

class LikesRequested extends LikesEvent {
  const LikesRequested();
}

class LikeResponded extends LikesEvent {
  const LikeResponded(this.like, {required this.likeBack});
  final ReceivedLike like;
  final bool likeBack;
  @override
  List<Object?> get props => [like, likeBack];
}

class LikesMatchSeen extends LikesEvent {
  const LikesMatchSeen();
}

enum LikesStatus { loading, ready, failure }

class LikesState extends Equatable {
  const LikesState({this.status = LikesStatus.loading, this.likes = const [], this.newMatch, this.error});

  final LikesStatus status;
  final List<ReceivedLike> likes;
  final Match? newMatch;
  final String? error;

  LikesState copyWith({LikesStatus? status, List<ReceivedLike>? likes, Match? Function()? newMatch, String? error}) =>
      LikesState(
        status: status ?? this.status,
        likes: likes ?? this.likes,
        newMatch: newMatch != null ? newMatch() : this.newMatch,
        error: error,
      );

  @override
  List<Object?> get props => [status, likes, newMatch, error];
}

/// "Likes You" – people who already liked the user (Hinge / Bumble Beeline).
class LikesBloc extends Bloc<LikesEvent, LikesState> {
  LikesBloc(this._repo) : super(const LikesState()) {
    on<LikesRequested>(_onRequested);
    on<LikeResponded>(_onResponded);
    on<LikesMatchSeen>((_, emit) => emit(state.copyWith(newMatch: () => null)));
  }

  final DiscoveryRepository _repo;

  Future<void> _onRequested(LikesRequested e, Emitter<LikesState> emit) async {
    if (state.likes.isEmpty) emit(state.copyWith(status: LikesStatus.loading));
    try {
      emit(state.copyWith(status: LikesStatus.ready, likes: await _repo.receivedLikes()));
    } on ApiException catch (err) {
      emit(state.copyWith(status: LikesStatus.failure, error: err.message));
    }
  }

  Future<void> _onResponded(LikeResponded e, Emitter<LikesState> emit) async {
    final remaining = state.likes.where((l) => l.profile.id != e.like.profile.id).toList();
    emit(state.copyWith(likes: remaining));
    try {
      final result = await _repo.swipe(
        profileId: e.like.profile.id,
        action: e.likeBack ? SwipeAction.like : SwipeAction.pass,
      );
      if (result.isMatch) emit(state.copyWith(newMatch: () => result.match));
    } on ApiException catch (err) {
      emit(state.copyWith(likes: [e.like, ...remaining], error: err.message));
    }
  }
}
