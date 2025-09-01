import 'package:flutter_bloc/flutter_bloc.dart';

class ButtonCubit extends Cubit<String> {
  ButtonCubit() : super('All'); // Default selected button is 'All'

  void selectButton(String buttonName) {
    emit(buttonName);
  }
}