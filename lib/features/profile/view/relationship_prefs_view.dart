import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../../discovery/view_model/discovery_bloc.dart';
import '../view_model/edit_profile_cubit.dart';
import '../view_model/profile_bloc.dart';
import 'my_profile_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// "What you're looking for": intention, who to meet, and dealbreakers.
class RelationshipPrefsView extends StatelessWidget {
  const RelationshipPrefsView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileBloc>().state.profile;
    final discovery = context.read<DiscoveryBloc>();
    if (profile == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => RelationshipPrefsCubit(profile: profile, prefs: discovery.state.preferences),
      child: BlocBuilder<RelationshipPrefsCubit, RelationshipPrefsState>(
        builder: (context, s) {
          final cubit = context.read<RelationshipPrefsCubit>();
          return LumeScaffold(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            header: LumeHeader(title: AppStrings.prefsTitle, onBack: () => context.pop()),
            body: StaggeredEntrance(
              spacing: 16,
              children: [
                Text(AppStrings.intention, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in RelationshipIntent.values)
                      LumeTag(
                        i.label,
                        variant: s.intent == i ? TagVariant.selected : TagVariant.normal,
                        onTap: () => cubit.intentSelected(i),
                      ),
                  ],
                ),
                Text(AppStrings.openToMeeting, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in InterestedIn.values)
                      LumeTag(
                        i.label,
                        variant: s.interestedIn == i ? TagVariant.selected : TagVariant.normal,
                        onTap: () => cubit.interestedInSelected(i),
                      ),
                  ],
                ),
                LumeCard(
                  children: [
                    LumeRow(
                      title: AppStrings.kids,
                      value: s.kids,
                      chevron: true,
                      onTap: () => _pick(
                        context,
                        AppStrings.kids,
                        RelationshipPrefsCubit.kidsOptions,
                        s.kids,
                        cubit.kidsChanged,
                      ),
                    ),
                    LumeRow(
                      title: AppStrings.smoking,
                      value: s.smoking,
                      onTap: () => _pick(
                        context,
                        AppStrings.smoking,
                        RelationshipPrefsCubit.smokingOptions,
                        s.smoking,
                        cubit.smokingChanged,
                      ),
                    ),
                    LumeRow(
                      title: AppStrings.distance,
                      value: AppStrings.km(s.distanceKm),
                      onTap: () => _pick(
                        context,
                        AppStrings.distance,
                        [for (final d in RelationshipPrefsCubit.distanceOptions) AppStrings.km(d)],
                        AppStrings.km(s.distanceKm),
                        (v) => cubit.distanceChanged(int.parse(v.split(' ').first)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottom: [
              SaveProfileButton(
                label: AppStrings.save,
                changes: () {
                  discovery.add(
                    PreferencesApplied(
                      discovery.state.preferences.copyWith(interestedIn: s.interestedIn, maxDistanceKm: s.distanceKm),
                    ),
                  );
                  return {
                    'intent': s.intent.value,
                    'lifestyle': {...profile.lifestyle, Lifestyle.kids: s.kids, Lifestyle.smoking: s.smoking},
                  };
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onPick,
  ) async {
    final picked = await showLumeSheet<String>(
      context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: LumeText.titleM.copyWith(color: AppColors.plum)),
            ),
            for (final o in options)
              LumeRow(
                title: o,
                chevron: false,
                trailing: o == current ? const Icon(Icons.check_rounded, color: AppColors.coral) : null,
                onTap: () => Navigator.pop(sheet, o),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPick(picked);
  }
}
