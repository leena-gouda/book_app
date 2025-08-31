import 'package:book_app/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomHomeTitle extends StatelessWidget {
  final String text;
  const CustomHomeTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:  TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold,color: AppColor.black),
    );
  }
}
