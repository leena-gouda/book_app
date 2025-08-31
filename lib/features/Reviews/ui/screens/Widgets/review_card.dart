import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../bookDetails/ui/screens/widgets/custom_rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final userName = review['user_name'] ?? 'Anonymous';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at'] != null
        ? DateTime.parse(review['created_at'])
        : DateTime.now();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              CustomRatingStars(rating: rating,),
              SizedBox(width: 8.w),
              Text(
                _formatDate(createdAt),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Text(
            comment,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
