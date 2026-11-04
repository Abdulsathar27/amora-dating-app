import 'package:flutter_bloc/flutter_bloc.dart';

/// Tiny Cubit for local UI drafts (dialogs, sheets) so those widgets can stay
/// StatelessWidget while still holding editable values.
class ValueCubit<T> extends Cubit<T> {
  ValueCubit(super.initial);

  void set(T value) => emit(value);
  void update(T Function(T current) fn) => emit(fn(state));
}
