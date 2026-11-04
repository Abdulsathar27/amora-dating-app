import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/auth_form_cubit.dart';
import 'splash_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthFormCubit(),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => showSnack(context, state.error!),
        child: const _AuthBody(),
      ),
    );
  }
}

class _AuthBody extends StatelessWidget {
  const _AuthBody();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const AmoraLogo(size: 40, light: true),
                  const SizedBox(height: 8),
                  Text(
                    'Meet someone worth staying for.',
                    style: text.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 32),
                  const _AuthCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard();

  @override
  Widget build(BuildContext context) {
    final form = context.read<AuthFormCubit>();
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<AuthFormCubit, AuthFormState>(
          builder: (context, s) {
            String? err(String? e) => s.showErrors ? e : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.isLogin ? 'Welcome back' : 'Create your account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (!s.isLogin) ...[
                  TextField(
                    key: const ValueKey('name'),
                    onChanged: form.nameChanged,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'First name',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: err(s.nameError),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const ValueKey('email'),
                  onChanged: form.emailChanged,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.mail_outline),
                    errorText: err(s.emailError),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('password'),
                  onChanged: form.passwordChanged,
                  obscureText: s.obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: err(s.passwordError),
                    suffixIcon: IconButton(
                      icon: Icon(s.obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: form.toggleObscure,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocSelector<AuthBloc, AuthState, bool>(
                  selector: (a) => a.isSubmitting,
                  builder: (context, submitting) => GradientButton(
                    label: s.isLogin ? 'Log in' : 'Sign up',
                    loading: submitting,
                    onPressed: () {
                      if (!form.validate()) return;
                      final auth = context.read<AuthBloc>();
                      auth.add(s.isLogin
                          ? AuthLoginRequested(s.email, s.password)
                          : AuthRegisterRequested(s.name, s.email, s.password));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: form.toggleMode,
                  child: Text(s.isLogin ? "New here? Create an account" : 'Already have an account? Log in'),
                ),
                Text(
                  'By continuing you agree to our Terms and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
