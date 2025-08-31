import 'package:book_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextAuth extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  const CustomTextAuth({super.key, required this.text,   this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14.sp, color: AppColor.textGray),
    );
  }
}