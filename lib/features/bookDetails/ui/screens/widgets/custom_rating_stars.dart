import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomRatingStars extends StatelessWidget {
  final double rating;
  const CustomRatingStars({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: 16.sp,
          color: index < rating ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }
}

