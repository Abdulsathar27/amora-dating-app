import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/match.dart';
import '../../auth/view/splash_view.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../../profile/view_model/profile_bloc.dart';
import '../view_model/discovery_bloc.dart';
import 'match_dialog.dart';
import 'preferences_sheet.dart';
import 'swipe_card.dart';

class DiscoveryView extends StatelessWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryBloc, DiscoveryState>(
      listenWhen: (a, b) => (b.newMatch != null && a.newMatch != b.newMatch) || (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) showSnack(context, s.error!);
        final match = s.newMatch;
        if (match != null) {
          context.read<DiscoveryBloc>().add(const MatchOverlayDismissed());
          context.read<MatchesBloc>().add(const MatchesRequested());
          showMatchDialog(context, match);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AmoraLogo(),
          actions: [
            IconButton(
              tooltip: 'Discovery settings',
              icon: const Icon(Icons.tune),
              onPressed: () => showPreferencesSheet(context),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, s) {
              final bloc = context.read<DiscoveryBloc>();
              if (s.status == DiscoveryStatus.loading || s.status == DiscoveryStatus.initial) {
                return const LoadingView();
              }
              if (s.status == DiscoveryStatus.failure) {
                return ErrorView(message: s.error ?? 'Could not load', onRetry: () => bloc.add(const DiscoveryStarted()));
              }
              if (s.deck.isEmpty) {
                return EmptyView(
                  icon: Icons.travel_explore,
                  title: "You've seen everyone nearby",
                  subtitle: 'Widen your distance or age range to meet more people.',
                  action: OutlinedButton(onPressed: () => showPreferencesSheet(context), child: const Text('Adjust filters')),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (s.deck.length > 1)
                            Positioned.fill(child: SwipeCard(profile: s.deck[1], isTop: false)),
                          Positioned.fill(
                            child: SwipeCard(
                              key: ValueKey(s.top!.id),
                              profile: s.top!,
                              isTop: true,
                              offset: s.dragOffset,
                              animate: !s.isDragging,
                              photoIndex: s.photoIndex,
                              likeProgress: s.swipeProgress,
                              superLikeProgress: s.superLikeProgress,
                              onDetails: () => AppRouter.openProfileDetail(context, s.top!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ActionBar(state: s),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});
  final DiscoveryState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DiscoveryBloc>();
    final busy = state.flyingOut != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundButton(
            icon: Icons.replay,
            color: AppColors.rewind,
            size: 46,
            onTap: state.canRewind ? () => bloc.add(const RewindRequested()) : null,
          ),
          _RoundButton(
            icon: Icons.close_rounded,
            color: AppColors.nope,
            size: 62,
            onTap: busy ? null : () => bloc.add(const SwipeRequested(SwipeAction.pass)),
          ),
          _RoundButton(
            icon: Icons.star_rounded,
            color: AppColors.superLike,
            size: 46,
            onTap: busy ? null : () => bloc.add(const SwipeRequested(SwipeAction.superLike)),
          ),
          _RoundButton(
            icon: Icons.favorite_rounded,
            color: AppColors.like,
            size: 62,
            onTap: busy ? null : () => bloc.add(const SwipeRequested(SwipeAction.like)),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.color, required this.size, this.onTap});
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      shape: const CircleBorder(),
      elevation: enabled ? 4 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: enabled ? color : Colors.grey, size: size * 0.5),
        ),
      ),
    );
  }
}

void showMatchDialog(BuildContext context, Match match) {
  final me = context.read<ProfileBloc>().state.profile;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => MatchDialog(
      match: match,
      myPhoto: me?.mainPhoto,
      onMessage: () {
        Navigator.of(dialogContext).pop();
        AppRouter.openChat(context, match);
      },
    ),
  );
}
