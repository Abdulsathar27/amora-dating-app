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
import '../view_model/profile_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Profile tab: identity, completeness, next step and settings rows.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, s) {
            final p = s.profile;
            if (p == null) {
              return s.status == ProfileStatus.failure
                  ? LumeEmptyState(
                    icon: LumeIcons.refresh,
                    title: AppStrings.profileLoadFailed,
                    body: s.error ?? AppStrings.pleaseTryAgain,
                    actionLabel: AppStrings.tryAgain,
                    onAction: () => context.read<ProfileBloc>().add(const ProfileRequested()),
                  )
                  : const Center(child: CircularProgressIndicator(color: AppColors.plum));
            }
            final pct = (s.completeness * 100).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              children: [
                Row(
                  children: [
                    Text(AppStrings.profile, style: LumeText.displayL),
                    const Spacer(),
                    LumeIconButton(
                      LumeIcons.shield,
                      tooltip: AppStrings.safetyCentre,
                      background: AppColors.surface,
                      bordered: true,
                      onPressed: () => context.push(AppRoutes.safetyCentre),
                    ),
                  ],
                ),
                AppGaps.h16,
                FadeRise(
                  child: Row(
                    children: [
                      ArchPhoto(source: p.mainPhoto, width: 104, height: 136, shadow: LumeShadows.soft),
                      AppGaps.w16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.name}, ${p.age}', style: LumeText.titleL.copyWith(color: AppColors.plum)),
                            AppGaps.h6,
                            if (p.isVerified) const StatusChip(label: AppStrings.verified, icon: LumeIcons.verified),
                            AppGaps.h6,
                            Text(AppStrings.percentComplete(pct), style: LumeText.labelM),
                            AppGaps.h6,
                            // Completion bar fills in on first show.
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: s.completeness),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder:
                                  (_, v, _) => ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: v,
                                      minHeight: 8,
                                      color: AppColors.coral,
                                      backgroundColor: AppColors.line,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.voice == null) ...[
                  AppGaps.h16,
                  PressScale(
                    scale: 0.98,
                    onTap: () => context.push(AppRoutes.voiceIntro),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const LumeIcon(LumeIcons.mic, size: 22),
                          AppGaps.w10,
                          Expanded(
                            child: Text(
                              AppStrings.addVoiceTo100,
                              style: LumeText.labelM.copyWith(color: AppColors.plum),
                            ),
                          ),
                          const LumeIcon(LumeIcons.next, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
                AppGaps.h16,
                LumeCard(
                  children: [
                    StaggeredEntrance(
                      children: [
                        LumeRow(
                          icon: LumeIcons.edit,
                          title: AppStrings.editProfile,
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        LumeRow(
                          icon: LumeIcons.image,
                          title: AppStrings.managePhotos,
                          onTap: () => context.push(AppRoutes.managePhotos),
                        ),
                        LumeRow(
                          icon: LumeIcons.mic,
                          title: AppStrings.voiceIntro,
                          onTap: () => context.push(AppRoutes.voiceIntro),
                        ),
                        LumeRow(
                          icon: LumeIcons.heart,
                          title: AppStrings.relationshipPreferences,
                          onTap: () => context.push(AppRoutes.relationshipPrefs),
                        ),
                        LumeRow(
                          icon: LumeIcons.lock,
                          title: AppStrings.privacy,
                          onTap: () => context.push(AppRoutes.privacy),
                        ),
                        LumeRow(
                          icon: LumeIcons.user,
                          title: AppStrings.account,
                          onTap: () => context.push(AppRoutes.account),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shared Save button that closes the screen once ProfileBloc reports a save.
class SaveProfileButton extends StatelessWidget {
  const SaveProfileButton({super.key, required this.label, required this.changes, this.enabled = true});

  final String label;
  final Map<String, dynamic> Function() changes;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (a, b) => a.savedAt != b.savedAt || (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) return showLumeSnack(context, s.error!);
        if (context.canPop()) context.pop();
      },
      buildWhen: (a, b) => a.status != b.status,
      builder:
          (context, s) => LumeButton(
            label,
            loading: s.status == ProfileStatus.saving,
            onPressed: enabled ? () => context.read<ProfileBloc>().add(ProfileSaved(changes())) : null,
          ),
    );
  }
}
