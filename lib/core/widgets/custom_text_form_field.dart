import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final InputBorder? border;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.border,
    this.textStyle,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      style: textStyle ??
           TextStyle(
            fontSize: 14.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle ??
             TextStyle(
              fontSize: 14.sp,
              color: Color(0xFF676767),
              fontWeight: FontWeight.w500,
            ),
        border: border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0.r),
              borderSide: const BorderSide(color: Colors.black),
            ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0.r),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0.r),
          borderSide: const BorderSide(color: Colors.red),
        ),

        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}