
import 'package:amora/data/models/discovery.dart';
import 'package:amora/data/models/match.dart';
import 'package:amora/data/models/profile.dart';
import 'package:amora/data/repositories/discovery_repository.dart';
import 'package:amora/features/discovery/view_model/discovery_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

const _a = Profile(id: 'a', name: 'A', age: 25);
const _b = Profile(id: 'b', name: 'B', age: 26);
const _c = Profile(id: 'c', name: 'C', age: 27);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(SwipeAction.like));

  setUp(() {
    repo = _MockRepo();
    when(() => repo.preferences()).thenAnswer((_) async => const DiscoveryPreferences());
    when(() => repo.feed(limit: any(named: 'limit'))).thenAnswer((_) async => [_a, _b, _c]);
  });

  blocTest<DiscoveryBloc, DiscoveryState>(
    'loads the deck on start',
    build: () => DiscoveryBloc(repo),
    act: (b) => b.add(const DiscoveryStarted()),
    verify: (b) {
      expect(b.state.status, DiscoveryStatus.ready);
      expect(b.state.deck.map((p) => p.id), ['a', 'b', 'c']);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'small drag snaps back without swiping',
    build: () => DiscoveryBloc(repo),
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_a, _b, _c]),
    act: (b) => b
      ..add(const CardDragUpdated(Offset(40, 0)))
      ..add(const CardDragEnded()),
    verify: (b) {
      expect(b.state.dragOffset, Offset.zero);
      expect(b.state.deck.length, 3);
      verifyNever(() => repo.swipe(profileId: any(named: 'profileId'), action: any(named: 'action')));
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'right swipe past threshold likes and surfaces a match',
    build: () {
      when(() => repo.swipe(profileId: 'a', action: SwipeAction.like)).thenAnswer(
        (_) async => SwipeResult(isMatch: true, match: Match(id: 'm1', profile: _a, matchedAt: DateTime(2026))),
      );
      return DiscoveryBloc(repo);
    },
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_a, _b, _c]),
    act: (b) => b
      ..add(const CardDragUpdated(Offset(200, 0)))
      ..add(const CardDragEnded()),
    wait: const Duration(milliseconds: 400),
    verify: (b) {
      expect(b.state.deck.first.id, 'b');
      expect(b.state.newMatch?.id, 'm1');
      expect(b.state.canRewind, isFalse);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'pass enables rewind, rewind restores the card',
    build: () {
      when(() => repo.swipe(profileId: 'a', action: SwipeAction.pass))
          .thenAnswer((_) async => const SwipeResult(isMatch: false));
      when(() => repo.rewind()).thenAnswer((_) async => _a);
      return DiscoveryBloc(repo);
    },
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_a, _b, _c]),
    act: (b) async {
      b.add(const SwipeRequested(SwipeAction.pass));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      b.add(const RewindRequested());
    },
    wait: const Duration(milliseconds: 100),
    verify: (b) {
      expect(b.state.deck.first.id, 'a');
      expect(b.state.canRewind, isFalse);
    },
  );
}
