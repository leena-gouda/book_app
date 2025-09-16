import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'Widgets/review_card.dart';

class AllReviewsPage extends StatelessWidget {
  final String bookId;
  final List<Map<String, dynamic>> reviews;

  const AllReviewsPage({
    super.key,
    required this.bookId,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Reviews (${reviews.length})'.tr()),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: reviews.length,
        separatorBuilder: (context, index) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          return ReviewCard(review: reviews[index]);
        },
      ),
    );
  }
}