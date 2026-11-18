import 'package:amora/app.dart';
import 'package:amora/core/di/injector.dart';
import 'package:amora/core/router/app_router.dart';
import 'package:amora/core/theme/lume_tokens.dart';
import 'package:amora/data/models/user.dart';
import 'package:amora/data/repositories/match_repository.dart';
import 'package:amora/features/auth/view_model/auth_bloc.dart';
import 'package:amora/features/discovery/view/match_view.dart';
import 'package:amora/features/discovery/view/profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens every route of the real app (go_router + BLoCs + mock API) on a
/// 390x844 phone and fails on any exception or layout overflow.
void main() {
  setUpAll(() async {
    LumeText.useGoogleFonts = false;
    SharedPreferences.setMockInitialValues({'access_token': 'mock-access', 'refresh_token': 'mock-refresh'});
    await configureDependencies();
  });

  testWidgets('every Lumé screen renders without errors', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = AuthBloc(sl())..add(const AuthStarted());
    final router = buildRouter(auth);
    await tester.pumpWidget(LumeApp(auth: auth, router: router));

    Future<void> settle([int frames = 12]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> visit(String location, {Object? extra}) async {
      router.go(location, extra: extra);
      await settle();
      expect(tester.takeException(), isNull, reason: 'Error while showing $location');
    }

    Future<T> load<T>(Future<T> future) async {
      await tester.pump(const Duration(seconds: 1));
      return future;
    }

    // Splash animation, then the signed-in user lands on Discover.
    await settle(30);
    expect(tester.takeException(), isNull);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/discover');
    expect(find.byType(ProfileCard), findsWidgets);

    // Swipe Maya right: she likes back in the mock → "It's a Match!".
    await tester.drag(find.byType(ProfileCard).first, const Offset(320, 0));
    await settle(20);
    expect(tester.takeException(), isNull);
    expect(find.byType(MatchView), findsOneWidget);

    for (final path in [
      '/discover',
      '/filters',
      '/likes',
      '/matches',
      '/messages',
      '/profile',
      '/profile/edit',
      '/profile/photos',
      '/profile/voice',
      '/profile/preferences',
      '/profile/privacy',
      '/profile/account',
      '/profile/verification',
      '/safety',
      '/safety/dating',
      '/report/reason?user=u_maya&name=Maya',
      '/report/details?user=u_maya&name=Maya',
      '/report/sent',
    ]) {
      await visit(path);
    }

    final matches = await load(sl<MatchRepository>().matches());
    final maya = matches.firstWhere((m) => m.profile.name == 'Maya');
    final noor = matches.firstWhere((m) => m.profile.name == 'Noor');

    await visit('/person', extra: FullProfileArgs(maya.profile, fromDiscover: true));
    await visit('/match', extra: maya);
    await visit('/chat/${noor.id}', extra: noor); // new match → conversation starters
    await visit('/chat/${maya.id}', extra: maya); // text, reaction, voice, hidden photo

    // Chat sheets.
    for (final label in ['Share something', 'GIFs', 'Conversation options']) {
      await tester.tap(find.bySemanticsLabel(label).first);
      await settle();
      expect(tester.takeException(), isNull, reason: 'Error opening $label');
      Navigator.of(tester.element(find.byType(BottomSheet).first)).pop();
      await settle();
    }

    // Signed out → welcome & sign-in flow.
    auth.add(const AuthLogoutRequested());
    await settle();
    for (final path in ['/welcome', '/age', '/age/blocked', '/sign-in', '/sign-in/phone', '/sign-in/verify']) {
      await visit(path);
    }

    // Signed in without a profile → pledge + create-profile flow.
    auth.add(const AuthSignedIn(AppUser(id: 'me', name: 'Maya', email: '')));
    await settle();
    for (final path in [
      '/pledge',
      '/create/name',
      '/create/identity',
      '/create/photos',
      '/create/intention',
      '/create/interests',
      '/create/voice',
      '/create/selfie',
      '/create/location',
      '/create/ready',
    ]) {
      await visit(path);
    }

    // Dispose everything and let pending mock timers finish.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
