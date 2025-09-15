import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/monthly_reading_model.dart';

class ReadingActivityChart extends StatelessWidget {
  final List<MonthlyReadingData> data;
  final int maxValue;
  final Function(String) onFilterChanged; // Add callback
  final String currentFilter; // Add current filter

  const ReadingActivityChart({
    super.key,
    required this.data,
    required this.maxValue,
    required this.onFilterChanged,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Chart bars
          Container(
            height: 150.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((monthData) {
                final heightPercentage = maxValue > 0
                    ? monthData.pagesRead / maxValue
                    : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bar
                    Container(
                      width: 20.w,
                      height: 100.h * heightPercentage,
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Month label
                    Text(
                      monthData.month,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColor.textGray,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Value label
                    Text(
                      '${monthData.pagesRead}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // X-axis line
          Container(
            height: 1.h,
            color: Colors.grey[300],
            margin: EdgeInsets.only(top: 8.h),
          ),

          // Time filter buttons
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeFilterButton('6M', currentFilter == '6M'),
              SizedBox(width: 16.w),
              _buildTimeFilterButton('1Y', currentFilter == '1Y'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () => onFilterChanged(text), // Call the callback
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? AppColor.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? AppColor.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: isActive ? Colors.white : AppColor.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}