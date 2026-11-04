import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/match.dart';
import '../../data/models/profile.dart';
import '../../features/chat/view/chat_view.dart';
import '../../features/chat/view_model/chat_bloc.dart';
import '../../features/matches/view_model/matches_bloc.dart';
import '../../features/profile/view/edit_profile_view.dart';
import '../../features/profile/view/profile_detail_view.dart';
import '../../features/profile/view_model/edit_profile_cubit.dart';
import '../../features/profile/view_model/profile_bloc.dart';
import '../../features/relationship/view_model/relationship_bloc.dart';
import '../di/injector.dart';

/// Pushed routes. Session-scoped ViewModels are forwarded with BlocProvider.value
/// so pushed screens share the same state as the tabs.
class AppRouter {
  AppRouter._();

  static Future<void> openChat(BuildContext context, Match match) async {
    final matches = context.read<MatchesBloc>();
    final relationship = context.read<RelationshipBloc>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: matches),
          BlocProvider.value(value: relationship),
          BlocProvider(create: (_) => ChatBloc(sl(), match)..add(const ChatOpened())),
        ],
        child: const ChatView(),
      ),
    ));
    matches.add(const MatchesRequested()); // refresh last message / unread badges
  }

  static Future<void> openProfileDetail(BuildContext context, Profile profile, {Widget? actions}) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ProfileDetailView(profile: profile, actions: actions),
    ));
  }

  static Future<void> openEditProfile(BuildContext context, Profile profile) {
    final profileBloc = context.read<ProfileBloc>();
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: profileBloc),
          BlocProvider(create: (_) => EditProfileCubit(profile)),
        ],
        child: const EditProfileView(),
      ),
    ));
  }
}
