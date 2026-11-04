import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../discovery/view/discovery_view.dart';
import '../../discovery/view_model/discovery_bloc.dart';
import '../../likes/view/likes_view.dart';
import '../../likes/view_model/likes_bloc.dart';
import '../../matches/view/matches_view.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../../profile/view/profile_view.dart';
import '../../profile/view_model/profile_bloc.dart';
import '../../relationship/view/relationship_view.dart';
import '../../relationship/view_model/relationship_bloc.dart';
import '../view_model/home_nav_cubit.dart';

/// Session scope: every ViewModel created here is disposed on logout.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeNavCubit()),
        BlocProvider(create: (_) => ProfileBloc(sl())..add(const ProfileRequested())),
        BlocProvider(create: (_) => DiscoveryBloc(sl())..add(const DiscoveryStarted())),
        BlocProvider(create: (_) => LikesBloc(sl())..add(const LikesRequested())),
        BlocProvider(create: (_) => MatchesBloc(sl())..add(const MatchesRequested())),
        BlocProvider(create: (_) => RelationshipBloc(sl())..add(const RelationshipLoaded())),
      ],
      child: const _HomeScaffold(),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<HomeNavCubit>().state;
    final unread = context.select<MatchesBloc, int>((b) => b.state.unreadTotal);
    final likes = context.select<LikesBloc, int>((b) => b.state.likes.length);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [DiscoveryView(), LikesView(), MatchesView(), RelationshipView(), ProfileView()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) {
          final next = HomeTab.values[i];
          context.read<HomeNavCubit>().select(next);
          // Refresh lightweight lists when the tab becomes visible.
          if (next == HomeTab.chats) context.read<MatchesBloc>().add(const MatchesRequested());
          if (next == HomeTab.likes) context.read<LikesBloc>().add(const LikesRequested());
          if (next == HomeTab.us) context.read<RelationshipBloc>().add(const RelationshipLoaded());
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), selectedIcon: Icon(Icons.local_fire_department), label: 'Discover'),
          NavigationDestination(
            icon: Badge(isLabelVisible: likes > 0, label: Text('$likes'), child: const Icon(Icons.favorite_border)),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Likes',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_outline)),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Us'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
