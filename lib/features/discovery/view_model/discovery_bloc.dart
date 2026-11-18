import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/match.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/discovery_repository.dart';

// ---------------- Events ----------------
sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();
  @override
  List<Object?> get props => [];
}

class DiscoveryStarted extends DiscoveryEvent {
  const DiscoveryStarted();
}

/// The top card left the screen (the view finished its fly-off animation).
class CardSwiped extends DiscoveryEvent {
  const CardSwiped(this.action, {this.comment});
  final SwipeAction action;

  /// Set when the like came from "Send a compliment".
  final String? comment;
  @override
  List<Object?> get props => [action, comment];
}

class MatchShown extends DiscoveryEvent {
  const MatchShown();
}

class PreferencesApplied extends DiscoveryEvent {
  const PreferencesApplied(this.preferences);
  final DiscoveryPreferences preferences;
  @override
  List<Object?> get props => [preferences];
}

// ---------------- State ----------------
enum DiscoveryStatus { loading, ready, offline }

class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.status = DiscoveryStatus.loading,
    this.deck = const [],
    this.preferences = const DiscoveryPreferences(),
    this.newMatch,
    this.likes = 0,
    this.error,
  });

  final DiscoveryStatus status;

  /// deck.first is the card on top.
  final List<Profile> deck;
  final DiscoveryPreferences preferences;

  /// Non-null right after a mutual like → the view opens "It's a Match!".
  final Match? newMatch;

  /// Count of likes sent; the view bounces the heart button when it changes.
  final int likes;
  final String? error;

  Profile? get top => deck.isEmpty ? null : deck.first;
  Profile? get next => deck.length < 2 ? null : deck[1];
  bool get isEmpty => status == DiscoveryStatus.ready && deck.isEmpty;

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<Profile>? deck,
    DiscoveryPreferences? preferences,
    Match? Function()? newMatch,
    int? likes,
    String? Function()? error,
  }) => DiscoveryState(
    status: status ?? this.status,
    deck: deck ?? this.deck,
    preferences: preferences ?? this.preferences,
    newMatch: newMatch != null ? newMatch() : this.newMatch,
    likes: likes ?? this.likes,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, deck, preferences, newMatch, likes, error];
}

// ---------------- ViewModel ----------------
/// Owns the deck. The swipe gesture and its AnimationController live in the
/// view; once a card has flown off, the view reports it with [CardSwiped].
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc(this._repo) : super(const DiscoveryState()) {
    on<DiscoveryStarted>(_onStarted);
    on<CardSwiped>(_onSwiped);
    on<MatchShown>((_, emit) => emit(state.copyWith(newMatch: () => null)));
    on<PreferencesApplied>(_onPreferences);
  }

  final DiscoveryRepository _repo;

  Future<void> _onStarted(DiscoveryStarted e, Emitter<DiscoveryState> emit) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, error: () => null));
    try {
      final prefs = await _repo.preferences();
      final deck = await _repo.feed();
      emit(state.copyWith(status: DiscoveryStatus.ready, deck: deck, preferences: prefs));
    } on ApiException catch (err) {
      emit(
        state.copyWith(
          status: err.statusCode == null ? DiscoveryStatus.offline : DiscoveryStatus.ready,
          error: () => err.message,
        ),
      );
    }
  }

  Future<void> _onSwiped(CardSwiped e, Emitter<DiscoveryState> emit) async {
    final target = state.top;
    if (target == null) return;
    final liked = e.action != SwipeAction.pass;
    emit(
      state.copyWith(
        deck: state.deck.skip(1).toList(),
        likes: liked ? state.likes + 1 : state.likes,
        error: () => null,
      ),
    );
    try {
      final result = await _repo.swipe(profileId: target.id, action: e.action, comment: e.comment);
      if (result.isMatch && result.match != null) emit(state.copyWith(newMatch: () => result.match));
      if (state.deck.length < 2) {
        final more = await _repo.feed();
        final known = {...state.deck.map((p) => p.id), target.id};
        emit(state.copyWith(deck: [...state.deck, ...more.where((p) => !known.contains(p.id))]));
      }
    } on ApiException catch (err) {
      // Likes are queued server-side; only a lost connection changes the screen.
      emit(
        state.copyWith(
          status: err.statusCode == null ? DiscoveryStatus.offline : state.status,
          error: () => err.message,
        ),
      );
    }
  }

  Future<void> _onPreferences(PreferencesApplied e, Emitter<DiscoveryState> emit) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, preferences: e.preferences));
    try {
      final (saved, _) = await _repo.savePreferences(e.preferences);
      final deck = await _repo.feed();
      emit(state.copyWith(status: DiscoveryStatus.ready, preferences: saved, deck: deck));
    } on ApiException catch (err) {
      emit(
        state.copyWith(
          status: err.statusCode == null ? DiscoveryStatus.offline : DiscoveryStatus.ready,
          error: () => err.message,
        ),
      );
    }
  }
}
