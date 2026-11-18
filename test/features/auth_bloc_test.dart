import 'package:amora/core/network/api_exception.dart';
import 'package:amora/data/models/user.dart';
import 'package:amora/data/repositories/auth_repository.dart';
import 'package:amora/features/auth/view_model/age_gate_cubit.dart';
import 'package:amora/features/auth/view_model/auth_bloc.dart';
import 'package:amora/features/auth/view_model/phone_auth_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  const user = AppUser(id: '1', name: 'Maya', email: '', isOnboarded: false);

  setUp(() {
    repo = _MockAuthRepo();
    when(() => repo.onSessionExpired).thenAnswer((_) => const Stream.empty());
  });

  group('AuthBloc', () {
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
      'signed in without a profile needs onboarding, then completes',
      build: () => AuthBloc(repo),
      act: (b) => b
        ..add(const AuthSignedIn(user))
        ..add(const AuthOnboardingCompleted(name: 'Maya')),
      verify: (b) {
        expect(b.state.status, AuthStatus.authenticated);
        expect(b.state.needsOnboarding, isFalse);
        expect(b.state.user?.name, 'Maya');
      },
    );
  });

  group('PhoneAuthCubit', () {
    blocTest<PhoneAuthCubit, PhoneAuthState>(
      'wrong code marks the digits as an error and bumps the shake',
      build: () {
        when(
          () => repo.verifyPhone(
            phone: any(named: 'phone'),
            code: any(named: 'code'),
          ),
        ).thenThrow(const ApiException('That code didn’t match.', statusCode: 400));
        return PhoneAuthCubit(repo);
      },
      seed: () => const PhoneAuthState(step: PhoneStep.enterCode, phone: '+44 7700 900123', code: '482610'),
      act: (c) => c.verify(),
      verify: (c) {
        expect(c.state.codeError, isTrue);
        expect(c.state.shake, 1);
        expect(c.state.canVerify, isFalse);
      },
    );

    blocTest<PhoneAuthCubit, PhoneAuthState>(
      'right code -> verified with the user',
      build: () {
        when(
          () => repo.verifyPhone(
            phone: any(named: 'phone'),
            code: '482613',
          ),
        ).thenAnswer((_) async => user);
        return PhoneAuthCubit(repo);
      },
      seed: () => const PhoneAuthState(step: PhoneStep.enterCode, phone: '+44 7700 900123', code: '482613'),
      act: (c) => c.verify(),
      verify: (c) {
        expect(c.state.step, PhoneStep.verified);
        expect(c.state.user, user);
      },
    );
  });

  group('AgeGateState', () {
    final today = DateTime(2026, 11, 18);

    test('exactly 18 today is an adult', () {
      expect(const AgeGateState(day: '18', month: '11', year: '2008').isAdult(today), isTrue);
    });

    test('one day short of 18 is blocked', () {
      expect(const AgeGateState(day: '19', month: '11', year: '2008').isAdult(today), isFalse);
    });

    test('impossible dates are incomplete', () {
      expect(const AgeGateState(day: '31', month: '02', year: '1998').isComplete, isFalse);
    });
  });
}
