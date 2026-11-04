import 'package:flutter_bloc/flutter_bloc.dart';

enum HomeTab { discover, likes, chats, us, profile }

class HomeNavCubit extends Cubit<HomeTab> {
  HomeNavCubit() : super(HomeTab.discover);

  void select(HomeTab tab) => emit(tab);
}
