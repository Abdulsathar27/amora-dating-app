import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/profile.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../discovery/view/preferences_sheet.dart';
import '../view_model/profile_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, s) {
          if (s.status == ProfileStatus.loading) return const LoadingView();
          final p = s.profile;
          if (p == null) {
            return ErrorView(
              message: s.error ?? 'Could not load profile',
              onRetry: () => context.read<ProfileBloc>().add(const ProfileRequested()),
            );
          }
          final completeness = _completeness(p);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 140,
                      child: CircularProgressIndicator(
                        value: completeness,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey.shade300,
                        color: AppColors.primary,
                      ),
                    ),
                    Avatar(p.mainPhoto, size: 124),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('${(completeness * 100).round()}% complete', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('${p.name}, ${p.age}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (p.jobTitle != null) Center(child: Text(p.jobTitle!)),
              const SizedBox(height: 24),
              _Tile(Icons.edit_outlined, 'Edit profile', () => AppRouter.openEditProfile(context, p)),
              _Tile(Icons.visibility_outlined, 'Preview my profile', () => AppRouter.openProfileDetail(context, p)),
              _Tile(Icons.tune, 'Discovery settings', () => showPreferencesSheet(context)),
              _Tile(Icons.verified_outlined, p.isVerified ? 'Verified' : 'Get verified', () {
                showSnack(context, 'Photo verification will be available once the backend is live.');
              }),
              _Tile(Icons.shield_outlined, 'Safety centre', () {
                showSnack(context, 'Tip: meet in public places and tell a friend your plans.');
              }),
              const Divider(height: 32),
              _Tile(Icons.logout, 'Log out', () => context.read<AuthBloc>().add(const AuthLogoutRequested()), danger: true),
            ],
          );
        },
      ),
    );
  }

  double _completeness(Profile p) {
    final checks = [
      p.photos.length >= 3,
      p.bio.length >= 20,
      p.prompts.isNotEmpty,
      p.interests.length >= 3,
      p.jobTitle != null,
      p.isVerified,
    ];
    return checks.where((c) => c).length / checks.length;
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.onTap, {this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.nope : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: danger ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
