import 'package:amora/core/network/api_exception.dart';
import 'package:amora/data/models/user.dart';
import 'package:amora/data/repositories/auth_repository.dart';
import 'package:amora/features/auth/view_model/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  const user = AppUser(id: '1', name: 'Sam', email: 'sam@x.com', isOnboarded: false);

  setUp(() {
    repo = _MockAuthRepo();
    when(() => repo.onSessionExpired).thenAnswer((_) => const Stream.empty());
  });

  blocTest<AuthBloc, AuthState>(
    'no stored token -> unauthenticated',
    build: () {
      when(() => repo.hasSession).thenReturn(false);
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
  );

  blocTest<AuthBloc, AuthState>(
    'register -> authenticated and needs onboarding',
    build: () {
      when(() => repo.register(name: 'Sam', email: 'sam@x.com', password: 'secret1')).thenAnswer((_) async => user);
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthRegisterRequested('Sam', 'sam@x.com', 'secret1')),
    verify: (b) {
      expect(b.state.status, AuthStatus.authenticated);
      expect(b.state.needsOnboarding, isTrue);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'login failure surfaces the API message',
    build: () {
      when(() => repo.login(email: 'sam@x.com', password: 'bad'))
          .thenThrow(const ApiException('Incorrect email or password', statusCode: 401));
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthLoginRequested('sam@x.com', 'bad')),
    verify: (b) {
      expect(b.state.isSubmitting, isFalse);
      expect(b.state.error, 'Incorrect email or password');
    },
  );
}
