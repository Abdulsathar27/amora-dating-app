import 'dart:ui' show Offset;

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

class CardDragUpdated extends DiscoveryEvent {
  const CardDragUpdated(this.delta);
  final Offset delta;
  @override
  List<Object?> get props => [delta];
}

class CardDragEnded extends DiscoveryEvent {
  const CardDragEnded();
}

class SwipeRequested extends DiscoveryEvent {
  const SwipeRequested(this.action);
  final SwipeAction action;
  @override
  List<Object?> get props => [action];
}

class RewindRequested extends DiscoveryEvent {
  const RewindRequested();
}

class PhotoTapped extends DiscoveryEvent {
  const PhotoTapped({required this.forward});
  final bool forward;
  @override
  List<Object?> get props => [forward];
}

class MatchOverlayDismissed extends DiscoveryEvent {
  const MatchOverlayDismissed();
}

class PreferencesUpdated extends DiscoveryEvent {
  const PreferencesUpdated(this.preferences);
  final DiscoveryPreferences preferences;
  @override
  List<Object?> get props => [preferences];
}

// ---------------- State ----------------
enum DiscoveryStatus { initial, loading, ready, failure }

class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.deck = const [],
    this.preferences = const DiscoveryPreferences(),
    this.dragOffset = Offset.zero,
    this.isDragging = false,
    this.flyingOut,
    this.photoIndex = 0,
    this.canRewind = false,
    this.newMatch,
    this.error,
  });

  final DiscoveryStatus status;

  /// deck.first is the card on top.
  final List<Profile> deck;
  final DiscoveryPreferences preferences;
  final Offset dragOffset;
  final bool isDragging;

  /// Non-null while the top card animates off-screen.
  final SwipeAction? flyingOut;
  final int photoIndex;
  final bool canRewind;
  final Match? newMatch;
  final String? error;

  Profile? get top => deck.isEmpty ? null : deck.first;

  /// -1 (nope) .. 1 (like) – drives the LIKE / NOPE stamps.
  double get swipeProgress => (dragOffset.dx / DiscoveryBloc.swipeThreshold).clamp(-1.0, 1.0);
  double get superLikeProgress => (-dragOffset.dy / DiscoveryBloc.superLikeThreshold).clamp(0.0, 1.0);

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<Profile>? deck,
    DiscoveryPreferences? preferences,
    Offset? dragOffset,
    bool? isDragging,
    SwipeAction? Function()? flyingOut,
    int? photoIndex,
    bool? canRewind,
    Match? Function()? newMatch,
    String? error,
  }) =>
      DiscoveryState(
        status: status ?? this.status,
        deck: deck ?? this.deck,
        preferences: preferences ?? this.preferences,
        dragOffset: dragOffset ?? this.dragOffset,
        isDragging: isDragging ?? this.isDragging,
        flyingOut: flyingOut != null ? flyingOut() : this.flyingOut,
        photoIndex: photoIndex ?? this.photoIndex,
        canRewind: canRewind ?? this.canRewind,
        newMatch: newMatch != null ? newMatch() : this.newMatch,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, deck, preferences, dragOffset, isDragging, flyingOut, photoIndex, canRewind, newMatch, error];
}

// ---------------- ViewModel ----------------
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc(this._repo) : super(const DiscoveryState()) {
    on<DiscoveryStarted>(_onStarted);
    on<CardDragUpdated>(_onDragUpdated);
    on<CardDragEnded>(_onDragEnded);
    on<SwipeRequested>(_onSwipe);
    on<RewindRequested>(_onRewind);
    on<PhotoTapped>(_onPhotoTapped);
    on<MatchOverlayDismissed>((_, emit) => emit(state.copyWith(newMatch: () => null)));
    on<PreferencesUpdated>(_onPreferences);
  }

  final DiscoveryRepository _repo;

  static const double swipeThreshold = 120;
  static const double superLikeThreshold = 160;
  static const Duration flyOutDuration = Duration(milliseconds: 260);

  Future<void> _onStarted(DiscoveryStarted e, Emitter<DiscoveryState> emit) async {
    emit(state.copyWith(status: DiscoveryStatus.loading));
    try {
      final prefs = await _repo.preferences();
      final deck = await _repo.feed();
      emit(state.copyWith(status: DiscoveryStatus.ready, deck: deck, preferences: prefs, photoIndex: 0));
    } on ApiException catch (err) {
      emit(state.copyWith(status: DiscoveryStatus.failure, error: err.message));
    }
  }

  void _onDragUpdated(CardDragUpdated e, Emitter<DiscoveryState> emit) {
    if (state.flyingOut != null || state.top == null) return;
    emit(state.copyWith(dragOffset: state.dragOffset + e.delta, isDragging: true));
  }

  void _onDragEnded(CardDragEnded e, Emitter<DiscoveryState> emit) {
    final o = state.dragOffset;
    if (o.dx > swipeThreshold) return add(const SwipeRequested(SwipeAction.like));
    if (o.dx < -swipeThreshold) return add(const SwipeRequested(SwipeAction.pass));
    if (o.dy < -superLikeThreshold) return add(const SwipeRequested(SwipeAction.superLike));
    emit(state.copyWith(dragOffset: Offset.zero, isDragging: false)); // snap back
  }

  void _onPhotoTapped(PhotoTapped e, Emitter<DiscoveryState> emit) {
    final top = state.top;
    if (top == null || top.photos.isEmpty) return;
    final next = (state.photoIndex + (e.forward ? 1 : -1)).clamp(0, top.photos.length - 1);
    emit(state.copyWith(photoIndex: next));
  }

  Future<void> _onSwipe(SwipeRequested e, Emitter<DiscoveryState> emit) async {
    final target = state.top;
    if (target == null || state.flyingOut != null) return;

    final exit = switch (e.action) {
      SwipeAction.like => const Offset(600, 40),
      SwipeAction.pass => const Offset(-600, 40),
      SwipeAction.superLike => const Offset(0, -900),
    };
    emit(state.copyWith(flyingOut: () => e.action, dragOffset: exit, isDragging: false));
    await Future<void>.delayed(flyOutDuration);

    emit(state.copyWith(
      deck: state.deck.skip(1).toList(),
      dragOffset: Offset.zero,
      flyingOut: () => null,
      photoIndex: 0,
      canRewind: e.action == SwipeAction.pass,
    ));

    try {
      final result = await _repo.swipe(profileId: target.id, action: e.action);
      if (result.isMatch && result.match != null) emit(state.copyWith(newMatch: () => result.match));
      if (state.deck.length < 3) await _topUp(emit);
    } on ApiException catch (err) {
      emit(state.copyWith(error: err.message));
    }
  }

  Future<void> _onRewind(RewindRequested e, Emitter<DiscoveryState> emit) async {
    if (!state.canRewind) return;
    try {
      final profile = await _repo.rewind();
      emit(state.copyWith(deck: [profile, ...state.deck.where((p) => p.id != profile.id)], canRewind: false, photoIndex: 0));
    } on ApiException catch (err) {
      emit(state.copyWith(canRewind: false, error: err.message));
    }
  }

  Future<void> _onPreferences(PreferencesUpdated e, Emitter<DiscoveryState> emit) async {
    emit(state.copyWith(status: DiscoveryStatus.loading));
    try {
      final saved = await _repo.savePreferences(e.preferences);
      final deck = await _repo.feed();
      emit(state.copyWith(status: DiscoveryStatus.ready, preferences: saved, deck: deck, photoIndex: 0, canRewind: false));
    } on ApiException catch (err) {
      emit(state.copyWith(status: DiscoveryStatus.ready, error: err.message));
    }
  }

  Future<void> _topUp(Emitter<DiscoveryState> emit) async {
    final more = await _repo.feed();
    final known = state.deck.map((p) => p.id).toSet();
    emit(state.copyWith(deck: [...state.deck, ...more.where((p) => !known.contains(p.id))]));
  }
}
