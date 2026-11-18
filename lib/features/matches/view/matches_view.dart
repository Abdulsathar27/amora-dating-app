import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/match.dart';
import '../view_model/matches_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Your matches": waiting for your hello + getting to know.
class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, s) {
            if (s.status == MatchesStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.plum));
            }
            if (s.matches.isEmpty) {
              return LumeEmptyState(
                illustration: const _OverlappingArches(),
                title: AppStrings.matchesEmptyTitle,
                body: AppStrings.matchesEmptyBody,
                actionLabel: AppStrings.keepDiscovering,
                onAction: () => context.go(AppRoutes.discover),
              );
            }
            return RefreshIndicator(
              color: AppColors.plum,
              onRefresh: () async => context.read<MatchesBloc>().add(const MatchesRequested()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  const FadeRise(child: LumeTitle(AppStrings.yourMatches)),
                  if (s.newMatches.isNotEmpty) ...[
                    AppGaps.h18,
                    Text(AppStrings.waitingForHello, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                    AppGaps.h18,
                    SizedBox(
                      height: 158,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: s.newMatches.length,
                        separatorBuilder: (_, _) => AppGaps.w14,
                        itemBuilder: (_, i) => FadeRise(
                          delay: Duration(milliseconds: 70 * i),
                          child: _NewMatch(match: s.newMatches[i]),
                        ),
                      ),
                    ),
                  ],
                  if (s.conversations.isNotEmpty) ...[
                    AppGaps.h18,
                    Text(AppStrings.gettingToKnow, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                    AppGaps.h18,
                    LumeCard(
                      children: [
                        StaggeredEntrance(children: [for (final m in s.conversations) _Connection(match: m)]),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewMatch extends StatelessWidget {
  const _NewMatch({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppStrings.sayHelloTo(match.profile.name),
    child: PressScale(
      onTap: () => context.push(AppRoutes.chat(match.id), extra: match),
      child: Column(
        children: [
          ArchPhoto(
            source: match.profile.mainPhoto,
            width: 100,
            height: 134,
            borderColor: AppColors.coral,
            borderWidth: 2.5,
          ),
          AppGaps.h6,
          Text(match.profile.name, style: LumeText.labelM),
        ],
      ),
    ),
  );
}

class _Connection extends StatelessWidget {
  const _Connection({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          LumeAvatar(match.profile.mainPhoto, size: AppSizes.avatarMd),
          AppGaps.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.profile.name, style: LumeText.titleS),
                Text(matchedLabel(match.matchedAt), style: LumeText.bodyM),
              ],
            ),
          ),
          LumeIconButton(
            LumeIcons.chat,
            tooltip: AppStrings.messageName(match.profile.name),
            background: AppColors.lavenderSoft,
            onPressed: () => context.push(AppRoutes.chat(match.id), extra: match),
          ),
        ],
      ),
    );
  }
}

String matchedLabel(DateTime at) {
  final days = DateTime.now().difference(at).inDays;
  if (days < 1) return AppStrings.matchedToday;
  if (days < 7) return AppStrings.matchedDaysAgo(days);
  return AppStrings.matchedLastWeek;
}

/// Matches Empty illustration: lavender and blush arches overlapping.
class _OverlappingArches extends StatelessWidget {
  const _OverlappingArches();

  @override
  Widget build(BuildContext context) {
    Widget arch(Color fill, Color stroke) => Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.arch(140),
        border: Border.all(color: stroke, width: 1.5),
      ),
    );
    return SizedBox(
      width: 250,
      height: 220,
      child: Stack(
        children: [
          Positioned(left: 0, top: 10, child: arch(AppColors.lavenderSoft, AppColors.lavender)),
          Positioned(left: 110, top: 10, child: arch(AppColors.blush, AppColors.coral)),
        ],
      ),
    );
  }
}
