import 'package:amora/core/network/api_exception.dart';
import 'package:amora/data/models/discovery.dart';
import 'package:amora/data/models/match.dart';
import 'package:amora/data/models/profile.dart';
import 'package:amora/data/repositories/discovery_repository.dart';
import 'package:amora/features/discovery/view_model/compliment_cubit.dart';
import 'package:amora/features/discovery/view_model/discovery_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

const _maya = Profile(id: 'maya', name: 'Maya', age: 27);
const _leo = Profile(id: 'leo', name: 'Leo', age: 31);
const _dan = Profile(id: 'dan', name: 'Daniel', age: 33);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(SwipeAction.like));

  setUp(() {
    repo = _MockRepo();
    when(() => repo.preferences()).thenAnswer((_) async => const DiscoveryPreferences());
    when(() => repo.feed(limit: any(named: 'limit'))).thenAnswer((_) async => [_maya, _leo, _dan]);
  });

  blocTest<DiscoveryBloc, DiscoveryState>(
    'loads the deck on start',
    build: () => DiscoveryBloc(repo),
    act: (b) => b.add(const DiscoveryStarted()),
    verify: (b) {
      expect(b.state.status, DiscoveryStatus.ready);
      expect(b.state.deck.map((p) => p.id), ['maya', 'leo', 'dan']);
      expect(b.state.next?.id, 'leo');
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a lost connection shows the offline state',
    build: () {
      when(() => repo.feed(limit: any(named: 'limit'))).thenThrow(const ApiException('No internet connection.'));
      return DiscoveryBloc(repo);
    },
    act: (b) => b.add(const DiscoveryStarted()),
    verify: (b) => expect(b.state.status, DiscoveryStatus.offline),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a mutual like removes the card and surfaces the match',
    build: () {
      when(() => repo.swipe(profileId: 'maya', action: SwipeAction.like, comment: any(named: 'comment'))).thenAnswer(
        (_) async => SwipeResult(isMatch: true, match: Match(id: 'm1', profile: _maya, matchedAt: DateTime(2026))),
      );
      return DiscoveryBloc(repo);
    },
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_maya, _leo, _dan]),
    act: (b) => b.add(const CardSwiped(SwipeAction.like)),
    verify: (b) {
      expect(b.state.top?.id, 'leo');
      expect(b.state.newMatch?.id, 'm1');
      expect(b.state.likes, 1);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a compliment is sent as a like with the comment',
    build: () {
      when(
        () => repo.swipe(
          profileId: any(named: 'profileId'),
          action: any(named: 'action'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => const SwipeResult(isMatch: false));
      return DiscoveryBloc(repo);
    },
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_maya, _leo, _dan]),
    act: (b) => b.add(const CardSwiped(SwipeAction.like, comment: 'Great bookshop taste')),
    verify:
        (_) => verify(
          () => repo.swipe(profileId: 'maya', action: SwipeAction.like, comment: 'Great bookshop taste'),
        ).called(1),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'passing the last cards tops the deck up from the feed',
    build: () {
      when(
        () => repo.swipe(
          profileId: any(named: 'profileId'),
          action: any(named: 'action'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => const SwipeResult(isMatch: false));
      return DiscoveryBloc(repo);
    },
    seed: () => const DiscoveryState(status: DiscoveryStatus.ready, deck: [_maya]),
    act: (b) => b.add(const CardSwiped(SwipeAction.pass)),
    verify: (b) => expect(b.state.deck.map((p) => p.id), ['leo', 'dan']),
  );

  group('ComplimentCubit', () {
    blocTest<ComplimentCubit, ComplimentState>(
      'picking a suggestion replaces the text and rebuilds the field',
      build: ComplimentCubit.new,
      act: (c) => c.suggestionPicked('Your smile!'),
      expect: () => [const ComplimentState(text: 'Your smile!', version: 1)],
    );

    test('needs at least 3 characters', () {
      expect(const ComplimentState(text: 'hi').canSend, isFalse);
      expect(const ComplimentState(text: 'Hello!').canSend, isTrue);
    });
  });
}
