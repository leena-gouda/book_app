import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

class SignupLoginText extends StatelessWidget {
  final String text1;
  final String text2;
  final VoidCallback? onTap;

  const SignupLoginText({
    super.key,
    required this.text1,
    required this.text2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text1,
        style:  TextStyle(
          fontSize: 14.sp,
          color: AppColor.textGray,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: text2,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColor.primaryColor,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}