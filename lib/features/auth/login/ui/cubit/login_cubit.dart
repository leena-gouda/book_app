import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  //final GlobalKey<FormState> formKey2 = GlobalKey<FormState>();

  bool obscureText = true;

  void toggleObscureText() {
    obscureText = !obscureText;
    emit(LoginInitial());
  }

  void login(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() == true) {
      emit(LoginLoading());

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (response.session != null) {
          emit(LoginSuccess());
        } else {
          emit(LoginError(message: 'Login failed. Please check your credentials.'));
        }
      } on AuthException catch (e) {
        emit(LoginError(message: e.message));
      } catch (e) {
        emit(LoginError(message: 'Unexpected error: ${e.toString()}'));
      }
    }
  }
}
