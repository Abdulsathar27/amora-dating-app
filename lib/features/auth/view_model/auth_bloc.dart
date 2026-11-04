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

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested(this.email, this.password);
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class _AuthSessionExpired extends AuthEvent {
  const _AuthSessionExpired();
}

// ---------------- State ----------------
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.isSubmitting = false, this.error});

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? error;

  bool get needsOnboarding => status == AuthStatus.authenticated && !(user?.isOnboarded ?? false);

  AuthState copyWith({AuthStatus? status, AppUser? user, bool? isSubmitting, String? error}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );

  @override
  List<Object?> get props => [status, user, isSubmitting, error];
}

// ---------------- ViewModel ----------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOnboardingCompleted>(_onOnboarded);
    on<AuthLogoutRequested>(_onLogout);
    on<_AuthSessionExpired>((_, emit) => emit(const AuthState(status: AuthStatus.unauthenticated)));
    _expiredSub = _repo.onSessionExpired.listen((_) => add(const _AuthSessionExpired()));
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _expiredSub;

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    if (!_repo.hasSession) return emit(const AuthState(status: AuthStatus.unauthenticated));
    try {
      final user = await _repo.currentUser();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final user = await _repo.login(email: e.email.trim(), password: e.password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (err) {
      emit(state.copyWith(isSubmitting: false, error: err.message));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final user = await _repo.register(name: e.name.trim(), email: e.email.trim(), password: e.password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (err) {
      emit(state.copyWith(isSubmitting: false, error: err.message));
    }
  }

  void _onOnboarded(AuthOnboardingCompleted e, Emitter<AuthState> emit) {
    final user = state.user;
    if (user != null) emit(state.copyWith(user: user.copyWith(isOnboarded: true)));
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    try {
      await _repo.logout();
    } on ApiException {
      // Tokens are cleared regardless.
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
