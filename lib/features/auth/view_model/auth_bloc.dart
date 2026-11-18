import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';

// ---------------- Events ----------------
sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Phone verification succeeded.
class AuthSignedIn extends AuthEvent {
  const AuthSignedIn(this.user);
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted({this.name});
  final String? name;
  @override
  List<Object?> get props => [name];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthDeleteRequested extends AuthEvent {
  const AuthDeleteRequested();
}

class _AuthSessionExpired extends AuthEvent {
  const _AuthSessionExpired();
}

// ---------------- State ----------------
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final AppUser? user;

  bool get needsOnboarding => status == AuthStatus.authenticated && !(user?.isOnboarded ?? false);

  /// Changes whenever a different session begins, so session-scoped ViewModels reset.
  String get sessionKey => '${status.name}:${user?.id}';

  @override
  List<Object?> get props => [status, user];
}

// ---------------- ViewModel ----------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignedIn>((e, emit) => emit(AuthState(status: AuthStatus.authenticated, user: e.user)));
    on<AuthOnboardingCompleted>(_onOnboarded);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthDeleteRequested>(_onDelete);
    on<_AuthSessionExpired>((_, emit) => emit(const AuthState(status: AuthStatus.unauthenticated)));
    _expiredSub = _repo.onSessionExpired.listen((_) => add(const _AuthSessionExpired()));
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _expiredSub;

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    if (!_repo.hasSession) return emit(const AuthState(status: AuthStatus.unauthenticated));
    try {
      emit(AuthState(status: AuthStatus.authenticated, user: await _repo.currentUser()));
    } on ApiException {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  void _onOnboarded(AuthOnboardingCompleted e, Emitter<AuthState> emit) {
    final user = state.user;
    if (user != null) {
      emit(
        AuthState(
          status: state.status,
          user: user.copyWith(isOnboarded: true, name: e.name),
        ),
      );
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    try {
      await _repo.logout();
    } on ApiException {
      // Tokens are cleared regardless.
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onDelete(AuthDeleteRequested e, Emitter<AuthState> emit) async {
    try {
      await _repo.deleteAccount();
    } on ApiException {
      // Local session is cleared regardless.
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
