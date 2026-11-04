import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/value_cubit.dart';
import '../../../data/models/discovery.dart';
import '../view_model/discovery_bloc.dart';

void showPreferencesSheet(BuildContext context) {
  final discovery = context.read<DiscoveryBloc>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) => ValueCubit<DiscoveryPreferences>(discovery.state.preferences),
      child: PreferencesSheet(onSave: (p) => discovery.add(PreferencesUpdated(p))),
    ),
  );
}

class PreferencesSheet extends StatelessWidget {
  const PreferencesSheet({super.key, required this.onSave});

  final ValueChanged<DiscoveryPreferences> onSave;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<ValueCubit<DiscoveryPreferences>, DiscoveryPreferences>(
      builder: (context, p) {
        final cubit = context.read<ValueCubit<DiscoveryPreferences>>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discovery settings', style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Show me', style: t.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<InterestedIn>(
                  segments: [for (final i in InterestedIn.values) ButtonSegment(value: i, label: Text(i.label))],
                  selected: {p.interestedIn},
                  onSelectionChanged: (s) => cubit.set(p.copyWith(interestedIn: s.first)),
                ),
                const SizedBox(height: 20),
                Text('Age range: ${p.minAge} – ${p.maxAge}', style: t.titleSmall),
                RangeSlider(
                  values: RangeValues(p.minAge.toDouble(), p.maxAge.toDouble()),
                  min: 18,
                  max: 70,
                  divisions: 52,
                  onChanged: (r) => cubit.set(p.copyWith(minAge: r.start.round(), maxAge: r.end.round())),
                ),
                Text('Maximum distance: ${p.maxDistanceKm} km', style: t.titleSmall),
                Slider(
                  value: p.maxDistanceKm.toDouble(),
                  min: 1,
                  max: 160,
                  onChanged: (v) => cubit.set(p.copyWith(maxDistanceKm: v.round())),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Verified profiles only'),
                  value: p.verifiedOnly,
                  onChanged: (v) => cubit.set(p.copyWith(verifiedOnly: v)),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Apply',
                  onPressed: () {
                    onSave(p);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
