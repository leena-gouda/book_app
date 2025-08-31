import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'signup_state.dart';

class SignupCubit extends Cubit<SignUpState> {
  SignupCubit() : super(SignUpInitial());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  //final GlobalKey<FormState> formKey1 = GlobalKey<FormState>();

  bool obscureText = true;
  bool obscureText2 = true;

  void toggleObscureText() {
    obscureText = !obscureText;
    emit(SignUpInitial());
  }

  void toggleObscureText2() {
    obscureText2 = !obscureText2;
    emit(SignUpInitial());
  }

  void signUp(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() == true) {
      emit(SignUpLoading());

      if (passwordController.text != passwordConfirmController.text) {
        emit(SignUpError(message: 'Passwords do not match'));
        print('Passwords do not match');
        return;
      }

      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (response.user != null) {
          emit(SignUpSuccess());
        } else {
          emit(SignUpError(message: 'Sign-up failed. Please try again.'));
        }
      } on AuthException catch (e) {
        print('Supabase Auth error: ${e.message}');
        emit(SignUpError(message: e.message));
      } catch (e) {
        print('Unexpected error: $e');
        emit(SignUpError(message: 'Unexpected error: ${e.toString()}'));
      }
    }
  }
}
