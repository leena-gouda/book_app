import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTitleAuth extends StatelessWidget {
  final String text;
  const CustomTitleAuth({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold,),
    );
  }
}