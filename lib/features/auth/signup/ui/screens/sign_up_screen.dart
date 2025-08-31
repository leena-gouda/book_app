import 'package:book_app/core/utils/extensions/navigation_extensions.dart';
import 'package:book_app/core/widgets/custom_text_auth.dart';
import 'package:book_app/features/auth/signup/ui/screens/widgets/signup_social_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/app_utils.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_loading_app.dart';
import '../../../../../core/widgets/custom_title_auth.dart';
import '../../../../../core/widgets/custom_text_form_field.dart';
import '../cubit/signup_cubit.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupCubit(),
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: BlocConsumer<SignupCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpLoading) {
              showLoadingApp(context);
            }
            if (state is SignUpSuccess) {
              context.back();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sign up successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColor.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 6,
                  duration: const Duration(seconds: 3),
                ),
              );
              context.pushReplacementNamed(Routes.homeScreen);
            }
            if (state is SignUpError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: ${state.message}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 6,
                  duration: const Duration(seconds: 3),
                ),
              );
              context.back();
            }
          },
          builder: (context, state) {
            final signupCubit = context.read<SignupCubit>();
            return Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Title Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTitleAuth(text: "Create your account"),
                            SizedBox(height: 12.h),
                            CustomTextAuth(
                              text: "Create an account and explore a tailored library of captivating stories.",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        SizedBox(height: 36.h),

                        // Form Fields with clean borders
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email field with label
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                "Email address",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: TextFormField(
                                controller: signupCubit.emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "Enter your email address",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20.w,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!AppUtils.isEmailValid(value.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Password field with label
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                "Password",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: TextFormField(
                                obscureText: signupCubit.obscureText,
                                controller: signupCubit.passwordController,
                                keyboardType: TextInputType.visiblePassword,
                                decoration: InputDecoration(
                                  hintText: "Enter your password",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      signupCubit.toggleObscureText();
                                    },
                                    icon: Icon(
                                      signupCubit.obscureText
                                          ? CupertinoIcons.eye_fill
                                          : CupertinoIcons.eye_slash,
                                      color: Colors.grey[500],
                                      size: 20.w,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Confirm Password field with label
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                "Confirm Password",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: TextFormField(
                                obscureText: signupCubit.obscureText2,
                                controller: signupCubit.passwordConfirmController,
                                keyboardType: TextInputType.visiblePassword,
                                decoration: InputDecoration(
                                  hintText: "Confirm your password",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      signupCubit.toggleObscureText2();
                                    },
                                    icon: Icon(
                                      signupCubit.obscureText2
                                          ? CupertinoIcons.eye_fill
                                          : CupertinoIcons.eye_slash,
                                      color: Colors.grey[500],
                                      size: 20.w,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != signupCubit.passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Sign Up Button
                            CustomButton(
                              text: "Create new account",
                              borderRadius: 10.r,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  signupCubit.signUp(_formKey);
                                }
                              },
                            ),

                            SizedBox(height: 32.h),

                            // Divider with "or" text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    "or",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24.h),

                            // Social Sign Up
                            Container(
                              alignment: Alignment.center,
                              child: SignUpSocialRow(),
                            ),

                            SizedBox(height: 32.h),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14.sp,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.pushNamed(Routes.loginScreen);
                                  },
                                  child: Text(
                                    "Log in",
                                    style: TextStyle(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}