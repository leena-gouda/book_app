import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';


class CustButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? iconData;
  final Color? iconColor;
  final double? iconSize;
  final Color textColor;
  final bool hasBorder;
  final EdgeInsets margin;

  const CustButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.height = 70,
    this.width = 70,
    this.borderRadius = 4.0,
    this.textStyle,
    this.iconData,
    this.iconColor,
    this.iconSize,
    this.textColor = AppColor.white,
    this.hasBorder = false,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.grey[300],
          minimumSize: Size(width.w, height.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
            side: hasBorder
                ? const BorderSide(width: 1)
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