import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../safety/view_model/safety_cubits.dart';
import '../view_model/profile_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: LumeText.titleS.copyWith(color: AppColors.plum));
}

/// "Privacy": visibility, location and message consent switches.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, s) {
        final cubit = context.read<SettingsCubit>();
        LumeRow row(String key, String title, [String? sub]) =>
            LumeRow(title: title, subtitle: sub, toggle: s.settings.flag(key), onToggle: (v) => cubit.toggle(key, v));
        return LumeScaffold(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          header: LumeHeader(title: AppStrings.privacy, onBack: () => context.pop()),
          body: StaggeredEntrance(
            spacing: 16,
            children: [
              LumeCard(
                children: [
                  row('show_in_discover', AppStrings.showInDiscover, AppStrings.showInDiscoverSubtitle),
                  row('show_online', AppStrings.showOnline),
                  row('read_receipts', AppStrings.readReceipts),
                ],
              ),
              const _Section(AppStrings.location),
              LumeCard(
                children: [
                  row('approximate_distance', AppStrings.approxDistanceOnly, AppStrings.exactLocationNeverShared),
                ],
              ),
              const _Section(AppStrings.messages),
              LumeCard(
                children: [
                  row('hide_photos_until_approved', AppStrings.hidePhotosUntilApproved),
                  row('voice_from_matches_only', AppStrings.voiceFromMatchesOnly),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Account": sign-in details, verification, help, sign out, delete.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, s) {
        final verified = context.select<ProfileBloc, bool>((b) => b.state.profile?.isVerified ?? false);
        void soon() => showLumeSnack(context, AppStrings.backendComingSoon);
        return LumeScaffold(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          header: LumeHeader(title: AppStrings.account, onBack: () => context.pop()),
          body: StaggeredEntrance(
            spacing: 16,
            children: [
              LumeCard(
                children: [
                  LumeRow(
                    icon: LumeIcons.phone,
                    title: AppStrings.phoneNumber,
                    subtitle: s.settings.phoneMasked,
                    onTap: soon,
                  ),
                  LumeRow(
                    icon: LumeIcons.mail,
                    title: AppStrings.emailLabel,
                    subtitle: s.settings.email ?? AppStrings.addForRecovery,
                    onTap: soon,
                  ),
                  LumeRow(
                    icon: LumeIcons.key,
                    title: AppStrings.twoStep,
                    toggle: s.settings.twoStep,
                    onToggle: (v) => context.read<SettingsCubit>().toggle('two_step', v),
                  ),
                  LumeRow(
                    icon: LumeIcons.verified,
                    title: AppStrings.verification,
                    value: verified ? AppStrings.verified : AppStrings.notYet,
                    onTap: () => context.push(AppRoutes.verification),
                  ),
                ],
              ),
              LumeCard(
                children: [
                  LumeRow(icon: LumeIcons.bell, title: AppStrings.notifications, onTap: soon),
                  LumeRow(
                    icon: LumeIcons.help,
                    title: AppStrings.helpAndSupport,
                    onTap: () => context.push(AppRoutes.safetyCentre),
                  ),
                  LumeRow(
                    icon: LumeIcons.logout,
                    title: AppStrings.signOut,
                    chevron: false,
                    onTap: () => _confirmSignOut(context),
                  ),
                  LumeRow(
                    icon: LumeIcons.trash,
                    title: AppStrings.deleteAccount,
                    danger: true,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final ok = await showLumeSheet<bool>(
      context,
      builder: (sheet) => _ConfirmSheet(
        title: AppStrings.signOutTitle,
        body: AppStrings.signOutBody,
        confirm: AppStrings.signOut,
        onConfirm: () => Navigator.pop(sheet, true),
      ),
    );
    if (ok == true) auth.add(const AuthLogoutRequested());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final ok = await showLumeSheet<bool>(
      context,
      builder: (sheet) => _ConfirmSheet(
        title: AppStrings.deleteTitle,
        body: AppStrings.deleteBody,
        confirm: AppStrings.deleteAccount,
        danger: true,
        onConfirm: () => Navigator.pop(sheet, true),
      ),
    );
    if (ok == true) auth.add(const AuthDeleteRequested());
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirm,
    required this.onConfirm,
    this.danger = false,
  });

  final String title;
  final String body;
  final String confirm;
  final VoidCallback onConfirm;
  final bool danger;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: LumeText.displayM, textAlign: TextAlign.center),
        AppGaps.h12,
        Text(body, style: LumeText.bodyL, textAlign: TextAlign.center),
        AppGaps.h20,
        LumeButton(confirm, variant: danger ? LumeButtonVariant.danger : LumeButtonVariant.plum, onPressed: onConfirm),
        AppGaps.h8,
        LumeButton(AppStrings.cancel, variant: LumeButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

/// "You're verified."
class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.select<ProfileBloc, (bool, DateTime?)>(
      (b) => (b.state.profile?.isVerified ?? false, b.state.profile?.verifiedAt),
    );
    final date = p.$2 == null ? '' : AppStrings.verifiedOn(DateFormat('d MMMM y').format(p.$2!.toLocal()));
    return LumeScaffold(
      header: LumeHeader(title: AppStrings.verification, onBack: () => context.pop()),
      body: StaggeredEntrance(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppGaps.h16,
          Container(
            width: 180,
            height: 220,
            decoration: BoxDecoration(
              color: p.$1 ? AppColors.successSoft : AppColors.lavenderSoft,
              borderRadius: AppRadius.arch(180, bottom: 24),
            ),
            alignment: Alignment.center,
            child: LumeIcon(
              LumeIcons.verified,
              size: AppSizes.avatarXl,
              color: p.$1 ? AppColors.success : AppColors.plum,
            ),
          ),
          AppGaps.h16,
          LumeTitle(
            p.$1 ? AppStrings.youreVerified : AppStrings.notVerifiedYet,
            subtitle: p.$1 ? AppStrings.verifiedBadgeBody(date) : AppStrings.takeSelfieToVerify,
            center: true,
          ),
          AppGaps.h16,
          const LumeNote(AppStrings.scanDeleted, icon: LumeIcons.lock),
        ],
      ),
    );
  }
}
