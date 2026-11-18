import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgeGateState extends Equatable {
  const AgeGateState({this.day = '', this.month = '', this.year = ''});

  final String day;
  final String month;
  final String year;

  DateTime? get birthday {
    final d = int.tryParse(day), m = int.tryParse(month), y = int.tryParse(year);
    if (d == null || m == null || y == null || y < 1900 || m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    return date.month == m ? date : null; // rejects 31 Feb etc.
  }

  bool get isComplete => birthday != null;

  /// True when the birthday is at least 18 years ago.
  bool isAdult([DateTime? now]) {
    final b = birthday;
    if (b == null) return false;
    final today = now ?? DateTime.now();
    final eighteenth = DateTime(b.year + 18, b.month, b.day);
    return !eighteenth.isAfter(today);
  }

  AgeGateState copyWith({String? day, String? month, String? year}) =>
      AgeGateState(day: day ?? this.day, month: month ?? this.month, year: year ?? this.year);

  @override
  List<Object?> get props => [day, month, year];
}

/// "First, your birthday." Lumé is 18+ only; the date itself is never stored.
class AgeGateCubit extends Cubit<AgeGateState> {
  AgeGateCubit() : super(const AgeGateState());

  void dayChanged(String v) => emit(state.copyWith(day: v));
  void monthChanged(String v) => emit(state.copyWith(month: v));
  void yearChanged(String v) => emit(state.copyWith(year: v));
}
