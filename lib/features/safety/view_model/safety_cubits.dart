import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/settings.dart';
import '../../../data/repositories/safety_repository.dart';

// ---------------------------------------------------------------- settings
class SettingsState extends Equatable {
  const SettingsState({this.settings = const AppSettings(), this.loading = true, this.error});

  final AppSettings settings;
  final bool loading;
  final String? error;

  @override
  List<Object?> get props => [settings, loading, error];
}

/// Privacy and Account switches. Toggles are optimistic and roll back on error.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(const SettingsState());

  final SafetyRepository _repo;

  Future<void> load() async {
    try {
      emit(SettingsState(settings: await _repo.settings(), loading: false));
    } on ApiException catch (e) {
      emit(SettingsState(settings: state.settings, loading: false, error: e.message));
    }
  }

  Future<void> toggle(String key, bool value) async {
    final before = state.settings;
    emit(SettingsState(settings: before.withFlag(key, value), loading: false));
    try {
      emit(SettingsState(settings: await _repo.updateSetting(key, value), loading: false));
    } on ApiException catch (e) {
      emit(SettingsState(settings: before, loading: false, error: e.message));
    }
  }
}

// ------------------------------------------------------------------ report
class ReportState extends Equatable {
  const ReportState({
    this.reason,
    this.details = '',
    this.alsoBlock = true,
    this.submitting = false,
    this.sent = false,
    this.error,
  });

  final ReportReason? reason;
  final String details;
  final bool alsoBlock;
  final bool submitting;
  final bool sent;
  final String? error;

  ReportState copyWith({
    ReportReason? reason,
    String? details,
    bool? alsoBlock,
    bool? submitting,
    bool? sent,
    String? Function()? error,
  }) => ReportState(
    reason: reason ?? this.reason,
    details: details ?? this.details,
    alsoBlock: alsoBlock ?? this.alsoBlock,
    submitting: submitting ?? this.submitting,
    sent: sent ?? this.sent,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [reason, details, alsoBlock, submitting, sent, error];
}

/// Report flow: reason → details (+ also block) → sent. Also handles "Block Maya?".
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repo, {required this.userId}) : super(const ReportState());

  final SafetyRepository _repo;
  final String userId;

  void reasonPicked(ReportReason r) => emit(state.copyWith(reason: r));
  void detailsChanged(String v) => emit(state.copyWith(details: v));
  void alsoBlockChanged(bool v) => emit(state.copyWith(alsoBlock: v));

  Future<bool> submit() async {
    final reason = state.reason;
    if (reason == null) return false;
    emit(state.copyWith(submitting: true, error: () => null));
    try {
      await _repo.report(
        userId: userId,
        reason: reason,
        details: state.details.trim().isEmpty ? null : state.details.trim(),
        alsoBlock: state.alsoBlock,
      );
      emit(state.copyWith(submitting: false, sent: true));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, error: () => e.message));
      return false;
    }
  }

  Future<bool> block() async {
    emit(state.copyWith(submitting: true, error: () => null));
    try {
      await _repo.block(userId);
      emit(state.copyWith(submitting: false, sent: true));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, error: () => e.message));
      return false;
    }
  }
}
