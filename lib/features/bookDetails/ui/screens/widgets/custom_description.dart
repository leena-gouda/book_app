import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';

class CustomDescription extends StatelessWidget {
  final String text1;
  final String text2;

  const CustomDescription({
    super.key,
    required this.text1,
    required this.text2,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180.w, // fixed width for labels
            child: Text(
              text1,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                text2,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColor.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
