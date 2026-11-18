import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/profile.dart';
import '../../discovery/view_model/discovery_bloc.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/safety_cubits.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Safety centre".
class SafetyCentreView extends StatelessWidget {
  const SafetyCentreView({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = context.select<SettingsCubit, int>((c) => c.state.settings.blockedCount);
    void info(String text) => showLumeSnack(context, text);
    return LumeScaffold(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      header: LumeHeader(title: AppStrings.safetyCentre, onBack: () => context.pop()),
      body: StaggeredEntrance(
        spacing: 16,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.plum, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.safetyHeroTitle, style: LumeText.displayM.copyWith(color: AppColors.surface)),
                AppGaps.h8,
                Text(AppStrings.safetyHeroBody, style: LumeText.bodyM.copyWith(color: AppColors.lavender)),
              ],
            ),
          ),
          LumeCard(
            children: [
              LumeRow(icon: LumeIcons.flag, title: AppStrings.reportSomeone, onTap: () => context.go(AppRoutes.messages)),
              LumeRow(icon: LumeIcons.ban, title: AppStrings.blockedPeople, value: '$blocked', onTap: () => info(AppStrings.blockedPeopleInfo)),
              LumeRow(
                icon: LumeIcons.image,
                title: AppStrings.photoModeration,
                subtitle: AppStrings.photoModerationSubtitle,
                onTap: () => info(AppStrings.photoModerationInfo),
              ),
              LumeRow(
                icon: LumeIcons.pin,
                title: AppStrings.locationPrivacy,
                subtitle: AppStrings.approximateOnly,
                onTap: () => context.push(AppRoutes.privacy),
              ),
              LumeRow(icon: LumeIcons.compliment, title: AppStrings.datingSafelyAndConsent, onTap: () => context.push(AppRoutes.datingSafely)),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Good dates start with clear, kind communication."
class DatingSafelyView extends StatelessWidget {
  const DatingSafelyView({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (LumeIcons.check, AppStrings.askFirstTitle, AppStrings.askFirstBody),
      (LumeIcons.close, AppStrings.noIsFullTitle, AppStrings.noIsFullBody),
      (LumeIcons.people, AppStrings.meetPublicTitle, AppStrings.meetPublicBody),
      (LumeIcons.lock, AppStrings.noMoneyTitle, AppStrings.noMoneyBody),
    ];
    return LumeScaffold(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      header: LumeHeader(title: AppStrings.datingSafely, onBack: () => context.pop()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeRise(child: Text(AppStrings.datingSafelyHero, style: LumeText.displayL)),
          AppGaps.h16,
          LumeCard(
            children: [
              StaggeredEntrance(children: [for (final r in rows) LumeRow(icon: r.$1, title: r.$2, subtitle: r.$3)]),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Block Maya?" confirmation sheet. On success, removes them everywhere and
/// shows the "Thank you for telling us" screen.
Future<void> showBlockSheet(BuildContext context, Profile profile) {
  final matches = context.read<MatchesBloc>();
  final discovery = context.read<DiscoveryBloc>();
  final settings = context.read<SettingsCubit>();
  return showLumeSheet<void>(
    context,
    builder:
        (sheet) => BlocProvider(
          create: (_) => ReportCubit(sl(), userId: profile.id),
          child: BlocBuilder<ReportCubit, ReportState>(
            builder:
                (ctx, s) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LumeAvatar(profile.mainPhoto, size: AppSizes.avatarXl),
                      AppGaps.h12,
                      Text(AppStrings.blockQuestion(profile.name), style: LumeText.displayM),
                      AppGaps.h12,
                      Text(AppStrings.blockBody(profile.name), textAlign: TextAlign.center, style: LumeText.bodyL),
                      if (s.error != null) ...[AppGaps.h12, LumeNote(s.error!, danger: true)],
                      AppGaps.h12,
                      LumeButton(
                        AppStrings.block,
                        variant: LumeButtonVariant.danger,
                        loading: s.submitting,
                        onPressed: () async {
                          if (!await ctx.read<ReportCubit>().block()) return;
                          matches.add(MatchRemoved(profile.id));
                          discovery.add(const DiscoveryStarted());
                          settings.load();
                          if (sheet.mounted) Navigator.pop(sheet);
                          if (context.mounted) context.go(AppRoutes.reportSent);
                        },
                      ),
                      AppGaps.h12,
                      LumeButton(AppStrings.cancel, variant: LumeButtonVariant.ghost, onPressed: () => Navigator.pop(sheet)),
                    ],
                  ),
                ),
          ),
        ),
  );
}

/// "More" on a full profile: block or report.
Future<void> showProfileSafetySheet(BuildContext context, Profile profile) {
  return showLumeSheet<void>(
    context,
    builder:
        (sheet) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LumeRow(
                icon: LumeIcons.ban,
                title: AppStrings.block,
                subtitle: AppStrings.wontBeTold(profile.name),
                danger: true,
                onTap: () {
                  Navigator.pop(sheet);
                  showBlockSheet(context, profile);
                },
              ),
              LumeRow(
                icon: LumeIcons.flag,
                title: AppStrings.report,
                subtitle: AppStrings.ourTeamReviewsEveryReport,
                danger: true,
                onTap: () {
                  Navigator.pop(sheet);
                  context.push(AppRoutes.reportReason(profile.id, profile.name));
                },
              ),
            ],
          ),
        ),
  );
}
