import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the login/register form input so the view can stay a StatelessWidget.
class AuthFormState extends Equatable {
  const AuthFormState({
    this.isLogin = true,
    this.name = '',
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.showErrors = false,
  });

  final bool isLogin;
  final String name;
  final String email;
  final String password;
  final bool obscurePassword;
  final bool showErrors;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? get nameError => !isLogin && name.trim().length < 2 ? 'Enter your first name' : null;
  String? get emailError => _emailRe.hasMatch(email.trim()) ? null : 'Enter a valid email';
  String? get passwordError => password.length < 6 ? 'At least 6 characters' : null;
  bool get isValid => nameError == null && emailError == null && passwordError == null;

  AuthFormState copyWith({
    bool? isLogin,
    String? name,
    String? email,
    String? password,
    bool? obscurePassword,
    bool? showErrors,
  }) =>
      AuthFormState(
        isLogin: isLogin ?? this.isLogin,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        showErrors: showErrors ?? this.showErrors,
      );

  @override
  List<Object?> get props => [isLogin, name, email, password, obscurePassword, showErrors];
}

class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({bool isLogin = true}) : super(AuthFormState(isLogin: isLogin));

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void emailChanged(String v) => emit(state.copyWith(email: v));
  void passwordChanged(String v) => emit(state.copyWith(password: v));
  void toggleObscure() => emit(state.copyWith(obscurePassword: !state.obscurePassword));
  void toggleMode() => emit(state.copyWith(isLogin: !state.isLogin, showErrors: false));

  /// Returns true when the form may be submitted.
  bool validate() {
    emit(state.copyWith(showErrors: true));
    return state.isValid;
  }
}
