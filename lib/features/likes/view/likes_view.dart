import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/discovery_action.dart';
import '../../../data/models/match.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/likes_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "They noticed you." — likes grid, and the empty state.
class LikesView extends StatelessWidget {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LikesBloc, LikesState>(
      listenWhen: (a, b) => b.newMatch != null && a.newMatch != b.newMatch,
      listener: (context, s) {
        context.read<LikesBloc>().add(const LikesMatchSeen());
        context.read<MatchesBloc>().add(const MatchesRequested());
        context.push(AppRoutes.itsAMatch, extra: s.newMatch);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<LikesBloc, LikesState>(
            builder: (context, s) {
              if (s.status == LikesStatus.loading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.plum));
              }
              if (s.likes.isEmpty) {
                return LumeEmptyState(
                  icon: LumeIcons.heart,
                  archColor: AppColors.blush,
                  title: AppStrings.likesEmptyTitle,
                  body: AppStrings.likesEmptyBody,
                  actionLabel: AppStrings.addVoiceIntro,
                  onAction: () => context.push(AppRoutes.voiceIntro),
                );
              }
              return RefreshIndicator(
                color: AppColors.plum,
                onRefresh: () async => context.read<LikesBloc>().add(const LikesRequested()),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: FadeRise(
                          child: LumeTitle(AppStrings.likesTitle, subtitle: AppStrings.likedThisWeek(s.likes.length)),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 173 / 270,
                        ),
                        itemCount: s.likes.length,
                        itemBuilder:
                            (_, i) => FadeRise(
                              key: ValueKey(s.likes[i].profile.id),
                              delay: Duration(milliseconds: 60 * i),
                              child: _LikeTile(like: s.likes[i]),
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LikeTile extends StatelessWidget {
  const _LikeTile({required this.like});

  final ReceivedLike like;

  @override
  Widget build(BuildContext context) {
    final p = like.profile;
    final bloc = context.read<LikesBloc>();
    return Semantics(
      button: true,
      label: '${p.name}, ${p.age}. ${like.reason ?? ''}',
      child: PressScale(
        scale: 0.98,
        onTap: () async {
          final result = await context.push<Object?>(AppRoutes.person, extra: FullProfileArgs(p, fromDiscover: true));
          final action = DiscoveryActionResult.from(result);
          if (action != null) bloc.add(LikeResponded(like, likeBack: action.isLike));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder:
                    (_, b) => ArchPhoto(
                      source: p.mainPhoto,
                      width: b.maxWidth,
                      height: b.maxHeight,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(padding: const EdgeInsets.all(10), child: _Badge(like: like)),
                      ),
                    ),
              ),
            ),
            AppGaps.h8,
            Text('${p.name}, ${p.age}', style: LumeText.titleS.copyWith(color: AppColors.plum)),
            AppGaps.h8,
            Text(
              like.reason ?? AppStrings.likedYourProfile,
              style: LumeText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.like});

  final ReceivedLike like;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg) = switch (like.kind) {
      LikeKind.superLike => (AppStrings.superLike, LumeIcons.star, AppColors.lavender),
      LikeKind.compliment => (AppStrings.compliment, LumeIcons.compliment, AppColors.surface),
      LikeKind.like => (null, null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LumeIcon(icon!, size: 14),
          AppGaps.w4,
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: LumeText.caption.copyWith(color: AppColors.plum),
            ),
          ),
        ],
      ),
    );
  }
}
