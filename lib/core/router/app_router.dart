import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/match.dart';
import '../../data/models/profile.dart';
import '../../features/auth/view/phone_views.dart';
import '../../features/auth/view/sign_in_view.dart';
import '../../features/auth/view_model/auth_bloc.dart';
import '../../features/auth/view_model/phone_auth_cubit.dart';
import '../../features/chat/view/chat_view.dart';
import '../../features/discovery/view/discover_view.dart';
import '../../features/discovery/view/filters_view.dart';
import '../../features/discovery/view/full_profile_view.dart';
import '../../features/discovery/view/match_view.dart';
import '../../features/home/view/home_shell.dart';
import '../../features/likes/view/likes_view.dart';
import '../../features/matches/view/matches_view.dart';
import '../../features/matches/view/messages_view.dart';
import '../../features/onboarding/view/age_gate_view.dart';
import '../../features/onboarding/view/create_profile_views.dart';
import '../../features/onboarding/view/finish_setup_views.dart';
import '../../features/onboarding/view/pledge_view.dart';
import '../../features/onboarding/view/splash_view.dart';
import '../../features/onboarding/view/welcome_view.dart';
import '../../features/onboarding/view_model/profile_setup_cubit.dart';
import '../../features/profile/view/edit_profile_view.dart';
import '../../features/profile/view/manage_photos_view.dart';
import '../../features/profile/view/my_profile_view.dart';
import '../../features/profile/view/relationship_prefs_view.dart';
import '../../features/profile/view/settings_views.dart';
import '../../features/profile/view/voice_intro_view.dart';
import '../../features/safety/view/report_views.dart';
import '../../features/safety/view/safety_views.dart';
import '../../features/safety/view_model/safety_cubits.dart';
import '../di/injector.dart';
import 'app_routes.dart';
import 'transitions.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// go_router configuration. Auth state drives redirects:
/// signed out → welcome flow, signed in without a profile → pledge + create flow,
/// signed in with a profile → the five tabs.
GoRouter buildRouter(AuthBloc auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(auth.stream),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == AppRoutes.splash) return null; // splash decides when its animation ends
      final s = auth.state;
      switch (s.status) {
        case AuthStatus.unknown:
          return AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return AppRoutes.isPreAuth(loc) ? null : AppRoutes.welcome;
        case AuthStatus.authenticated:
          if (s.needsOnboarding) return AppRoutes.isOnboarding(loc) ? null : AppRoutes.pledge;
          return AppRoutes.isPreAuth(loc) || AppRoutes.isOnboarding(loc) ? AppRoutes.discover : null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, pageBuilder: (_, s) => LumeTransitions.dissolve(s, const SplashView())),

      // ------------------------------------------------ welcome & sign in
      GoRoute(path: AppRoutes.welcome, pageBuilder: (_, s) => LumeTransitions.dissolve(s, const WelcomeView())),
      GoRoute(
        path: AppRoutes.ageGate,
        pageBuilder: (_, s) => LumeTransitions.push(s, const AgeGateView()),
        routes: [GoRoute(path: 'blocked', pageBuilder: (_, s) => LumeTransitions.dissolve(s, const AgeBlockedView()))],
      ),
      GoRoute(path: AppRoutes.signIn, pageBuilder: (_, s) => LumeTransitions.push(s, const SignInView())),
      ShellRoute(
        builder: (_, _, child) => BlocProvider(create: (_) => PhoneAuthCubit(sl()), child: child),
        routes: [
          GoRoute(path: AppRoutes.phone, pageBuilder: (_, s) => LumeTransitions.push(s, const PhoneNumberView())),
          GoRoute(path: AppRoutes.verifyCode, pageBuilder: (_, s) => LumeTransitions.push(s, const VerifyCodeView())),
        ],
      ),

      // ------------------------------------------------ create your profile
      GoRoute(path: AppRoutes.pledge, pageBuilder: (_, s) => LumeTransitions.push(s, const PledgeView())),
      ShellRoute(
        builder:
            (context, _, child) => BlocProvider(
              create: (_) => ProfileSetupCubit(sl(), sl(), initialName: context.read<AuthBloc>().state.user?.name),
              child: child,
            ),
        routes: [
          GoRoute(path: AppRoutes.createName, pageBuilder: (_, s) => LumeTransitions.push(s, const CreateNameView())),
          GoRoute(
            path: AppRoutes.createIdentity,
            pageBuilder: (_, s) => LumeTransitions.push(s, const CreateIdentityView()),
          ),
          GoRoute(
            path: AppRoutes.createPhotos,
            pageBuilder: (_, s) => LumeTransitions.push(s, const CreatePhotosView()),
          ),
          GoRoute(
            path: AppRoutes.createIntention,
            pageBuilder: (_, s) => LumeTransitions.push(s, const CreateIntentionView()),
          ),
          GoRoute(
            path: AppRoutes.createInterests,
            pageBuilder: (_, s) => LumeTransitions.push(s, const CreateInterestsView()),
          ),
          GoRoute(path: AppRoutes.createVoice, pageBuilder: (_, s) => LumeTransitions.push(s, const CreateVoiceView())),
          GoRoute(
            path: AppRoutes.verifySelfie,
            pageBuilder: (_, s) => LumeTransitions.push(s, const VerifySelfieView()),
          ),
          GoRoute(
            path: AppRoutes.locationPrivacy,
            pageBuilder: (_, s) => LumeTransitions.push(s, const LocationPrivacyView()),
          ),
          GoRoute(
            path: AppRoutes.profileReady,
            pageBuilder: (_, s) => LumeTransitions.push(s, const ProfileReadyView()),
          ),
        ],
      ),

      // ------------------------------------------------ the five tabs
      StatefulShellRoute.indexedStack(
        pageBuilder: (_, s, shell) => LumeTransitions.dissolve(s, HomeShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.discover, builder: (_, _) => const DiscoverView())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.likes, builder: (_, _) => const LikesView())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.matches, builder: (_, _) => const MatchesView())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.messages, builder: (_, _) => const MessagesView())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const MyProfileView())]),
        ],
      ),

      // ------------------------------------------------ pushed over the tabs
      GoRoute(path: AppRoutes.filters, pageBuilder: (_, s) => LumeTransitions.moveIn(s, const FiltersView())),
      GoRoute(
        path: AppRoutes.itsAMatch,
        pageBuilder:
            (_, s) => LumeTransitions.dissolve(
              s,
              MatchView(match: s.extra! as Match),
              duration: const Duration(milliseconds: 480),
            ),
      ),
      GoRoute(
        path: AppRoutes.person,
        pageBuilder: (_, s) {
          final args = s.extra! as FullProfileArgs;
          return LumeTransitions.moveIn(s, FullProfileView(profile: args.profile, fromDiscover: args.fromDiscover));
        },
      ),
      GoRoute(
        path: '/chat/:matchId',
        pageBuilder:
            (_, s) =>
                LumeTransitions.push(s, ChatView(matchId: s.pathParameters['matchId']!, initial: s.extra as Match?)),
      ),
      GoRoute(path: AppRoutes.editProfile, pageBuilder: (_, s) => LumeTransitions.push(s, const EditProfileView())),
      GoRoute(path: AppRoutes.managePhotos, pageBuilder: (_, s) => LumeTransitions.push(s, const ManagePhotosView())),
      GoRoute(path: AppRoutes.voiceIntro, pageBuilder: (_, s) => LumeTransitions.push(s, const VoiceIntroView())),
      GoRoute(
        path: AppRoutes.relationshipPrefs,
        pageBuilder: (_, s) => LumeTransitions.push(s, const RelationshipPrefsView()),
      ),
      GoRoute(path: AppRoutes.privacy, pageBuilder: (_, s) => LumeTransitions.push(s, const PrivacyView())),
      GoRoute(path: AppRoutes.account, pageBuilder: (_, s) => LumeTransitions.push(s, const AccountView())),
      GoRoute(path: AppRoutes.verification, pageBuilder: (_, s) => LumeTransitions.push(s, const VerificationView())),
      GoRoute(path: AppRoutes.safetyCentre, pageBuilder: (_, s) => LumeTransitions.push(s, const SafetyCentreView())),
      GoRoute(path: AppRoutes.datingSafely, pageBuilder: (_, s) => LumeTransitions.push(s, const DatingSafelyView())),

      // ------------------------------------------------ report flow
      ShellRoute(
        builder:
            (_, s, child) => BlocProvider(
              create: (_) => ReportCubit(sl(), userId: s.uri.queryParameters['user'] ?? ''),
              child: child,
            ),
        routes: [
          GoRoute(
            path: '/report/reason',
            pageBuilder: (_, s) => LumeTransitions.push(s, ReportReasonView(name: s.uri.queryParameters['name'] ?? '')),
          ),
          GoRoute(path: '/report/details', pageBuilder: (_, s) => LumeTransitions.push(s, const ReportDetailsView())),
        ],
      ),
      GoRoute(path: AppRoutes.reportSent, pageBuilder: (_, s) => LumeTransitions.push(s, const ReportSentView())),
    ],
  );
}

/// Arguments for the "Full profile" screen.
class FullProfileArgs {
  const FullProfileArgs(this.profile, {this.fromDiscover = false});
  final Profile profile;

  /// Shows the sticky Pass / Compliment / Like / Super Like bar.
  final bool fromDiscover;
}

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
