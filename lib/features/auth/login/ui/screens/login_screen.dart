import 'package:book_app/core/utils/extensions/navigation_extensions.dart';
import 'package:book_app/core/widgets/custom_text_auth.dart';
import 'package:book_app/features/auth/login/ui/cubit/login_cubit.dart';
import 'package:book_app/features/auth/login/ui/screens/widgets/login_social_row.dart';
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

class LoginScreen extends StatelessWidget {
   LoginScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(toolbarHeight: 0),
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginLoading) {
            showLoadingApp(context);
          }
          if (state is LoginSuccess) {
            context.back();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Login successfully',
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
          if (state is LoginError) {
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
          final loginCubit = context.read<LoginCubit>();
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24,),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    //mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Title Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTitleAuth(text: "Log in"),
                          SizedBox(height: 12.h),
                          CustomTextAuth(
                            text: "Welcome back! Log in to resume your reading journey.",
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
                              controller: loginCubit.emailController,
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
                              obscureText: loginCubit.obscureText,
                              controller: loginCubit.passwordController,
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
                                    loginCubit.toggleObscureText();
                                  },
                                  icon: Icon(
                                    loginCubit.obscureText
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
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Login Button
                          CustomButton(
                            text: "Log in",
                            borderRadius: 10.r,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                loginCubit.login(_formKey);
                                Navigator.pushNamed(context, Routes.homeScreen);
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

                          // Social Login
                          Container(alignment: Alignment.center,child: LoginSocialRow()),

                          SizedBox(height: 32.h),

                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14.sp,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(Routes.signupsScreen);
                                },
                                child: Text(
                                  "Sign up",
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
    );
  }
}