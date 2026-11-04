import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/view/auth_view.dart';
import 'features/auth/view/splash_view.dart';
import 'features/auth/view_model/auth_bloc.dart';
import 'features/home/view/home_shell.dart';
import 'features/onboarding/view/onboarding_view.dart';

class AmoraApp extends StatelessWidget {
  const AmoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(sl())..add(const AuthStarted()),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (a, b) => a.status != b.status || a.needsOnboarding != b.needsOnboarding,
          builder: (context, state) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (state.status) {
              AuthStatus.unknown => const SplashView(),
              AuthStatus.unauthenticated => const AuthView(),
              AuthStatus.authenticated when state.needsOnboarding => const OnboardingView(),
              AuthStatus.authenticated => const HomeShell(),
            },
          ),
        ),
      ),
    );
  }
}
