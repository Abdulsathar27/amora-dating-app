import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/discovery_bloc.dart';
import 'swipe_deck.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Discover tab: deck, loading skeleton, "That's everyone", and offline states.
class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryBloc, DiscoveryState>(
      listenWhen: (a, b) => b.newMatch != null && a.newMatch != b.newMatch,
      listener: (context, s) {
        context.read<DiscoveryBloc>().add(const MatchShown());
        context.read<MatchesBloc>().add(const MatchesRequested());
        context.push(AppRoutes.itsAMatch, extra: s.newMatch);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _TopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 96),
                  child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                    builder:
                        (context, s) => AnimatedSwitcher(
                          duration: LumeMotion.dissolve,
                          child: switch (s.status) {
                            DiscoveryStatus.loading => const _Skeleton(key: ValueKey('loading')),
                            DiscoveryStatus.offline => LumeEmptyState(
                              key: const ValueKey('offline'),
                              illustration: Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(color: AppColors.lavenderSoft, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: const LumeIcon(LumeIcons.wifiOff, size: 54),
                              ),
                              title: AppStrings.offlineTitle,
                              body: AppStrings.offlineBody,
                              actionLabel: AppStrings.tryAgain,
                              onAction: () => context.read<DiscoveryBloc>().add(const DiscoveryStarted()),
                            ),
                            DiscoveryStatus.ready when s.isEmpty => LumeEmptyState(
                              key: const ValueKey('empty'),
                              illustration: const ArchPhoto(
                                source: 'assets/images/dunes.jpg',
                                width: 200,
                                height: 240,
                                bottomRadius: 24,
                              ),
                              title: AppStrings.emptyDeckTitle,
                              body: AppStrings.emptyDeckBody,
                              actionLabel: AppStrings.widenSearch,
                              onAction: () => context.push(AppRoutes.filters),
                            ),
                            DiscoveryStatus.ready => SwipeDeck(
                              key: const ValueKey('deck'),
                              top: s.top!,
                              next: s.next,
                              likes: s.likes,
                            ),
                          },
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: SizedBox(
      height: AppSizes.headerHeight,
      child: Row(
        children: [
          Text(AppStrings.wordmark, style: LumeText.wordmark.copyWith(fontSize: 26, height: 32 / 26)),
          const Spacer(),
          LumeIconButton(
            LumeIcons.sliders,
            tooltip: AppStrings.discoveryFilters,
            background: AppColors.surface,
            bordered: true,
            onPressed: () => context.push(AppRoutes.filters),
          ),
        ],
      ),
    ),
  );
}

/// "Discover Loading": shimmering arch + note skeleton.
class _Skeleton extends StatelessWidget {
  const _Skeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line(double w, [double h = 14]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(h / 2)),
    );
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (_, box) {
            final w = box.maxWidth;
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: w,
                  height: w * 362 / 358,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: AppRadius.arch(w, bottom: 28)),
                ),
                Positioned(
                  top: w * 362 / 358 - 56,
                  left: 12,
                  right: 12,
                  child: FadeRise(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 44),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: LumeShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          line(160),
                          AppGaps.h12,
                          line(110),
                          AppGaps.h12,
                          line(280),
                          AppGaps.h12,
                          line(200),
                          AppGaps.h12,
                          Row(children: [line(84, 32), AppGaps.w8, line(92, 32), AppGaps.w8, line(74, 32)]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
