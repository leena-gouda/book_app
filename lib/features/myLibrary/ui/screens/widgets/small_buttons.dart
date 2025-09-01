// small_buttons.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../cubit/button_cubit.dart';

class SmallButtons extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final String? circleText;
  final Color? circleColor;
  final double? circleRadius;
  final Color textColor;
  final bool hasBorder;
  final Color? circleTextColor;
  final Color selectedColor;
  final onPressed;

  const SmallButtons({
    super.key,
    required this.text,
    this.backgroundColor,
    this.height = 35,
    this.width = double.infinity,
    this.borderRadius = 28,
    this.textStyle,
    this.textColor = AppColor.white,
    this.hasBorder = false,
    this.circleText,
    this.circleColor,
    this.circleRadius = 12,
    this.circleTextColor = Colors.white,
    this.selectedColor = Colors.blue,
    this.onPressed,
    required bool isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ButtonCubit, String>(
      builder: (context, selectedButton) {
        final isSelected = selectedButton == text;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? selectedColor
                : (backgroundColor ?? Colors.white60),
            minimumSize: Size(width.w, height.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.r),
              side: hasBorder
                  ? const BorderSide(width: 1, color: Colors.grey)
                  : BorderSide.none,
            ),
            shadowColor: Colors.grey[300],
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: textStyle ??
                    TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (circleText != null) ...[
                SizedBox(width: 8.w),
                CircleAvatar(
                  radius: circleRadius!.r,
                  backgroundColor: isSelected
                      ? Colors.white
                      : (circleColor ?? Colors.grey.shade300),
                  child: Text(
                    circleText!,
                    style: TextStyle(
                      color: isSelected ? selectedColor : circleTextColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}