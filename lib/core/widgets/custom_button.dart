import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? iconData;
  final Color? iconColor;
  final double? iconSize;
  final Color textColor;
  final bool hasBorder;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.height = 55,
    this.borderRadius = 4.0,
    this.textStyle,
    this.iconData,
    this.iconColor,
    this.iconSize,
    this.textColor = AppColor.white,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColor.primaryColor,
        minimumSize: Size(double.infinity.w, height.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          side: hasBorder
              ? const BorderSide(color: AppColor.primaryColor, width: 1)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon:Icon(  // Create Icon widget here
      iconData,
      color: iconColor,
      size: iconSize,
    ),
      label: Text(
        text,
        style: textStyle ??
         TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w900,
        color: textColor,
        ),
      )
    );
  }
}