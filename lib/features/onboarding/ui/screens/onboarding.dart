import 'package:book_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        child: Stack(
          children: [
            // Background image with wash effect
            Positioned.fill(
              child: Image.asset(
                'assets/images/onboarding.png',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient overlay to wash out the image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.7),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 0.8],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    "Borrow library books\neasily and quickly!",
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColor.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Borrow library books easily and conveniently, with\nquick access anytime, anywhere.",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColor.descriptions,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),
                  CustomButton(
                    text: "Get Started",
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.loginScreen);
                    },
                    borderRadius: 12.r,
                    textColor: AppColor.white,
                    backgroundColor: AppColor.primaryColor,
                  ),
                  SizedBox(height: 12.h),
                  CustomButton(
                    text: "I'm new, Sign me up",
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.signupsScreen);
                    },
                    backgroundColor: AppColor.white,
                    borderRadius: 12.r,
                    textColor: AppColor.black,
                    hasBorder: true,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}