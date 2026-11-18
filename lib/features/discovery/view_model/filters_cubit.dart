import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';

/// Draft of "Who you'd like to meet". Applied to [DiscoveryBloc] on "Show N people".
class FiltersCubit extends Cubit<DiscoveryPreferences> {
  FiltersCubit(super.initial);

  void ageChanged(int min, int max) => emit(state.copyWith(minAge: min, maxAge: max));
  void distanceChanged(int km) => emit(state.copyWith(maxDistanceKm: km));
  void verifiedOnlyChanged(bool v) => emit(state.copyWith(verifiedOnly: v));
  void voiceIntroChanged(bool v) => emit(state.copyWith(hasVoiceIntro: v));

  void intentToggled(RelationshipIntent i) {
    final next = Set<RelationshipIntent>.of(state.lookingFor);
    next.contains(i) ? next.remove(i) : next.add(i);
    emit(state.copyWith(lookingFor: next));
  }

  /// Rough audience estimate for the CTA until the backend returns a count for drafts.
  int get estimate {
    final ageSpan = (state.maxAge - state.minAge + 1).clamp(1, 60);
    final base = ageSpan * 2 + state.maxDistanceKm + state.lookingFor.length * 5;
    return (base * (state.verifiedOnly ? 0.8 : 1) * (state.hasVoiceIntro ? 0.5 : 1)).round().clamp(1, 999);
  }
}
