import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/constants/app_strings.dart';

enum PhoneStep { enterNumber, sendingCode, enterCode, verifying, verified }

class PhoneAuthState extends Equatable {
  const PhoneAuthState({
    this.step = PhoneStep.enterNumber,
    this.phone = '+44 ',
    this.code = '',
    this.resendIn = 0,
    this.error,
    this.codeError = false,
    this.shake = 0,
    this.user,
  });

  final PhoneStep step;
  final String phone;
  final String code;

  /// Seconds until "Send a new code" becomes available.
  final int resendIn;
  final String? error;

  /// Wrong code: digits turn red and the Verify button is disabled until edited.
  final bool codeError;

  /// Bumped on each wrong code to replay the shake animation.
  final int shake;
  final AppUser? user;

  bool get phoneValid => phone.replaceAll(RegExp(r'\D'), '').length >= 10;
  bool get canVerify => code.length == 6 && !codeError && step != PhoneStep.verifying;

  String get resendLabel => AppStrings.resendCodeIn(resendIn);

  PhoneAuthState copyWith({
    PhoneStep? step,
    String? phone,
    String? code,
    int? resendIn,
    String? Function()? error,
    bool? codeError,
    int? shake,
    AppUser? user,
  }) => PhoneAuthState(
    step: step ?? this.step,
    phone: phone ?? this.phone,
    code: code ?? this.code,
    resendIn: resendIn ?? this.resendIn,
    error: error != null ? error() : this.error,
    codeError: codeError ?? this.codeError,
    shake: shake ?? this.shake,
    user: user ?? this.user,
  );

  @override
  List<Object?> get props => [step, phone, code, resendIn, error, codeError, shake, user];
}

/// Phone number → SMS code flow, shared by the "What's your number?" and "Enter the code" screens.
class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  PhoneAuthCubit(this._repo) : super(const PhoneAuthState());

  final AuthRepository _repo;
  Timer? _timer;

  void phoneChanged(String v) => emit(state.copyWith(phone: v, error: () => null));

  void codeChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    emit(state.copyWith(code: digits.length > 6 ? digits.substring(0, 6) : digits, codeError: false, error: () => null));
  }

  /// Returns true when the code was sent and the next screen should open.
  Future<bool> sendCode() async {
    if (!state.phoneValid) {
      emit(state.copyWith(error: () => AppStrings.enterFullNumber));
      return false;
    }
    emit(state.copyWith(step: PhoneStep.sendingCode, error: () => null));
    try {
      final wait = await _repo.startPhone(state.phone.trim());
      emit(state.copyWith(step: PhoneStep.enterCode, code: '', codeError: false));
      _startCountdown(wait);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(step: PhoneStep.enterNumber, error: () => e.message));
      return false;
    }
  }

  Future<void> resend() async {
    if (state.resendIn > 0) return;
    await sendCode();
  }

  Future<void> verify() async {
    if (!state.canVerify) return;
    emit(state.copyWith(step: PhoneStep.verifying));
    try {
      final user = await _repo.verifyPhone(phone: state.phone.trim(), code: state.code);
      _timer?.cancel();
      emit(state.copyWith(step: PhoneStep.verified, user: user));
    } on ApiException catch (e) {
      emit(state.copyWith(step: PhoneStep.enterCode, codeError: true, shake: state.shake + 1, error: () => e.message));
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    emit(state.copyWith(resendIn: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.resendIn - 1;
      if (next <= 0) t.cancel();
      emit(state.copyWith(resendIn: next < 0 ? 0 : next));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
