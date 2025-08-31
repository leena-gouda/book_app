import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/app_colors.dart';

class CustomLoginWithGoogle extends StatelessWidget {
  final String imagePath;
  final void Function()? onTap;

  const CustomLoginWithGoogle({super.key, required this.imagePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 304.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Login with Google",
                style: TextStyle(
                    color: AppColor.primaryColor, fontSize: 14.sp, fontWeight: FontWeight.w500)),
            10.horizontalSpace,
            SvgPicture.asset(imagePath, width: 16.w, height: 16.h),
          ],
        ),
      ),
    );
  }
}