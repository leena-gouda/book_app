import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void changeTab(int newIndex) {
    if (newIndex != state) {
      emit(newIndex);
    }
  }
}