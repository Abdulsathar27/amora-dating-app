import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../view_model/discovery_bloc.dart';
import '../view_model/filters_cubit.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Who you'd like to meet" — discovery filters.
class FiltersView extends StatelessWidget {
  const FiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    final discovery = context.read<DiscoveryBloc>();
    return BlocProvider(
      create: (_) => FiltersCubit(discovery.state.preferences),
      child: BlocBuilder<FiltersCubit, DiscoveryPreferences>(
        builder: (context, p) {
          final cubit = context.read<FiltersCubit>();
          return LumeScaffold(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            header: LumeHeader(title: AppStrings.filtersTitle, close: true, onBack: () => context.pop()),
            body: StaggeredEntrance(
              spacing: 18,
              children: [
                const SizedBox(height: 0),
                LumeCard(
                  children: [
                    _RangeRow(
                      title: AppStrings.age,
                      value: AppStrings.ageRange(p.minAge, p.maxAge),
                      child: RangeSlider(
                        values: RangeValues(p.minAge.toDouble(), p.maxAge.toDouble()),
                        min: 18,
                        max: 70,
                        divisions: 52,
                        onChanged: (r) => cubit.ageChanged(r.start.round(), r.end.round()),
                      ),
                    ),
                    _RangeRow(
                      title: AppStrings.distance,
                      value: AppStrings.upToKm(p.maxDistanceKm),
                      child: Slider(
                        value: p.maxDistanceKm.toDouble(),
                        min: 1,
                        max: 100,
                        onChanged: (v) => cubit.distanceChanged(v.round()),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.lookingFor, style: LumeText.titleS),
                    AppGaps.h10,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final i in RelationshipIntent.values)
                          LumeTag(
                            i.filterLabel,
                            variant: p.lookingFor.contains(i) ? TagVariant.selected : TagVariant.normal,
                            onTap: () => cubit.intentToggled(i),
                          ),
                      ],
                    ),
                  ],
                ),
                LumeCard(
                  children: [
                    LumeRow(
                      title: AppStrings.verifiedOnly,
                      toggle: p.verifiedOnly,
                      onToggle: cubit.verifiedOnlyChanged,
                    ),
                    LumeRow(
                      title: AppStrings.hasVoiceIntro,
                      toggle: p.hasVoiceIntro,
                      onToggle: cubit.voiceIntroChanged,
                    ),
                  ],
                ),
              ],
            ),
            bottom: [
              LumeButton(
                AppStrings.showPeople(cubit.estimate),
                onPressed: () {
                  discovery.add(PreferencesApplied(p));
                  context.pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.title, required this.value, required this.child});

  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      children: [
        Row(
          children: [
            Text(title, style: LumeText.titleS),
            const Spacer(),
            Text(value, style: LumeText.bodyM),
          ],
        ),
        SizedBox(height: 36, child: child),
      ],
    ),
  );
}
