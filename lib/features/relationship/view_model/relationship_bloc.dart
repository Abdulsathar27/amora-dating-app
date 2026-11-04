import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/relationship.dart';
import '../../../data/repositories/relationship_repository.dart';

// ---------------- Events ----------------
sealed class RelationshipEvent extends Equatable {
  const RelationshipEvent();
  @override
  List<Object?> get props => [];
}

class RelationshipLoaded extends RelationshipEvent {
  const RelationshipLoaded();
}

class PartnerRequestSent extends RelationshipEvent {
  const PartnerRequestSent(this.matchId);
  final String matchId;
  @override
  List<Object?> get props => [matchId];
}

class PartnerRequestAnswered extends RelationshipEvent {
  const PartnerRequestAnswered({required this.accept});
  final bool accept;
  @override
  List<Object?> get props => [accept];
}

class RelationshipEnded extends RelationshipEvent {
  const RelationshipEnded();
}

class DatePlanAdded extends RelationshipEvent {
  const DatePlanAdded({required this.title, required this.scheduledAt, this.place});
  final String title;
  final DateTime scheduledAt;
  final String? place;
  @override
  List<Object?> get props => [title, scheduledAt, place];
}

class DatePlanStatusChanged extends RelationshipEvent {
  const DatePlanStatusChanged(this.plan, this.status);
  final DatePlan plan;
  final DatePlanStatus status;
  @override
  List<Object?> get props => [plan, status];
}

class MemoryAdded extends RelationshipEvent {
  const MemoryAdded({required this.title, required this.date, this.note});
  final String title;
  final DateTime date;
  final String? note;
  @override
  List<Object?> get props => [title, date, note];
}

class MoodCheckedIn extends RelationshipEvent {
  const MoodCheckedIn(this.mood);
  final Mood mood;
  @override
  List<Object?> get props => [mood];
}

// ---------------- State ----------------
enum RelationshipViewStatus { loading, ready, failure }

class RelationshipState extends Equatable {
  const RelationshipState({
    this.status = RelationshipViewStatus.loading,
    this.relationship = Relationship.empty,
    this.datePlans = const [],
    this.memories = const [],
    this.checkIns = const [],
    this.isBusy = false,
    this.error,
  });

  final RelationshipViewStatus status;
  final Relationship relationship;
  final List<DatePlan> datePlans;
  final List<Memory> memories;
  final List<CheckIn> checkIns;
  final bool isBusy;
  final String? error;

  bool get isActive => relationship.status == RelationshipStatus.active;

  List<DatePlan> get upcomingPlans =>
      datePlans.where((p) => p.status == DatePlanStatus.planned).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  CheckIn? get todaysCheckIn {
    final now = DateTime.now();
    for (final c in checkIns) {
      final d = c.createdAt.toLocal();
      if (d.year == now.year && d.month == now.month && d.day == now.day) return c;
    }
    return null;
  }

  RelationshipState copyWith({
    RelationshipViewStatus? status,
    Relationship? relationship,
    List<DatePlan>? datePlans,
    List<Memory>? memories,
    List<CheckIn>? checkIns,
    bool? isBusy,
    String? error,
  }) =>
      RelationshipState(
        status: status ?? this.status,
        relationship: relationship ?? this.relationship,
        datePlans: datePlans ?? this.datePlans,
        memories: memories ?? this.memories,
        checkIns: checkIns ?? this.checkIns,
        isBusy: isBusy ?? this.isBusy,
        error: error,
      );

  @override
  List<Object?> get props => [status, relationship, datePlans, memories, checkIns, isBusy, error];
}

// ---------------- ViewModel ----------------
/// The "Us" space: turns a match into an in-app relationship with shared
/// date plans, memories, mood check-ins and an anniversary counter.
class RelationshipBloc extends Bloc<RelationshipEvent, RelationshipState> {
  RelationshipBloc(this._repo) : super(const RelationshipState()) {
    on<RelationshipLoaded>(_onLoaded);
    on<PartnerRequestSent>(_onRequest);
    on<PartnerRequestAnswered>(_onAnswer);
    on<RelationshipEnded>(_onEnded);
    on<DatePlanAdded>(_onPlanAdded);
    on<DatePlanStatusChanged>(_onPlanStatus);
    on<MemoryAdded>(_onMemoryAdded);
    on<MoodCheckedIn>(_onMood);
  }

  final RelationshipRepository _repo;

  Future<void> _onLoaded(RelationshipLoaded e, Emitter<RelationshipState> emit) async {
    try {
      final rel = await _repo.current();
      if (rel.status != RelationshipStatus.active) {
        return emit(state.copyWith(status: RelationshipViewStatus.ready, relationship: rel));
      }
      final results = await Future.wait([_repo.datePlans(), _repo.memories(), _repo.checkIns()]);
      emit(state.copyWith(
        status: RelationshipViewStatus.ready,
        relationship: rel,
        datePlans: results[0] as List<DatePlan>,
        memories: results[1] as List<Memory>,
        checkIns: results[2] as List<CheckIn>,
      ));
    } on ApiException catch (err) {
      emit(state.copyWith(status: RelationshipViewStatus.failure, error: err.message));
    }
  }

  Future<void> _onRequest(PartnerRequestSent e, Emitter<RelationshipState> emit) =>
      _busy(emit, () async => emit(state.copyWith(relationship: await _repo.request(e.matchId))));

  Future<void> _onAnswer(PartnerRequestAnswered e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        await _repo.respond(accept: e.accept);
        add(const RelationshipLoaded());
      });

  Future<void> _onEnded(RelationshipEnded e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        await _repo.end();
        emit(const RelationshipState(status: RelationshipViewStatus.ready));
      });

  Future<void> _onPlanAdded(DatePlanAdded e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        final plan = await _repo.addDatePlan(title: e.title, scheduledAt: e.scheduledAt, place: e.place);
        emit(state.copyWith(datePlans: [plan, ...state.datePlans]));
      });

  Future<void> _onPlanStatus(DatePlanStatusChanged e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        final updated = await _repo.updateDatePlanStatus(e.plan.id, e.status);
        emit(state.copyWith(datePlans: [for (final p in state.datePlans) p.id == updated.id ? updated : p]));
      });

  Future<void> _onMemoryAdded(MemoryAdded e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        final m = await _repo.addMemory(title: e.title, date: e.date, note: e.note);
        emit(state.copyWith(memories: [m, ...state.memories]));
      });

  Future<void> _onMood(MoodCheckedIn e, Emitter<RelationshipState> emit) => _busy(emit, () async {
        final c = await _repo.addCheckIn(e.mood);
        emit(state.copyWith(checkIns: [c, ...state.checkIns]));
      });

  Future<void> _busy(Emitter<RelationshipState> emit, Future<void> Function() body) async {
    emit(state.copyWith(isBusy: true));
    try {
      await body();
      emit(state.copyWith(isBusy: false));
    } on ApiException catch (err) {
      emit(state.copyWith(isBusy: false, error: err.message));
    }
  }
}
