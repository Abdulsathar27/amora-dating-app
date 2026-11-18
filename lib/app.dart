import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/view_model/auth_bloc.dart';
import 'features/discovery/view_model/discovery_bloc.dart';
import 'features/likes/view_model/likes_bloc.dart';
import 'features/matches/view_model/matches_bloc.dart';
import 'features/profile/view_model/profile_bloc.dart';
import 'features/relationship/view_model/relationship_bloc.dart';
import 'features/safety/view_model/safety_cubits.dart';

class LumeApp extends StatelessWidget {
  const LumeApp({super.key, required this.auth, required this.router});

  final AuthBloc auth;
  final GoRouter router;

  /// Builds the app with its own AuthBloc and router.
  factory LumeApp.create() {
    final auth = AuthBloc(sl())..add(const AuthStarted());
    return LumeApp(auth: auth, router: buildRouter(auth));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: auth,
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => _SessionScope(child: child!),
      ),
    );
  }
}

/// Session-scoped ViewModels live above the Navigator so every route (tabs and
/// pushed screens) shares them. A new key on sign-in/sign-out recreates them.
/// They are lazy: nothing is fetched until a screen first reads them.
class _SessionScope extends StatelessWidget {
  const _SessionScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) => a.sessionKey != b.sessionKey,
      builder:
          (context, auth) => MultiBlocProvider(
            key: ValueKey(auth.sessionKey),
            providers: [
              BlocProvider(create: (_) => ProfileBloc(sl())..add(const ProfileRequested())),
              BlocProvider(create: (_) => DiscoveryBloc(sl())..add(const DiscoveryStarted())),
              BlocProvider(create: (_) => LikesBloc(sl())..add(const LikesRequested())),
              BlocProvider(create: (_) => MatchesBloc(sl())..add(const MatchesRequested())),
              BlocProvider(create: (_) => SettingsCubit(sl())..load()),
              BlocProvider(create: (_) => RelationshipBloc(sl())),
            ],
            child: child,
          ),
    );
  }
}
