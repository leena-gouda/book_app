// features/reviews/ui/screens/Widgets/review_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool showBookInfo;
  final String? bookTitle;
  final List<String>? bookAuthors;
  final String? bookThumbnail;

  const ReviewCard({
    super.key,
    required this.review,
    this.showBookInfo = false,
    this.bookTitle,
    this.bookAuthors,
    this.bookThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBookInfo && bookTitle != null) ...[
              _buildBookInfo(),
              SizedBox(height: 12.h),
              Divider(height: 1.h),
              SizedBox(height: 12.h),
            ],
            Row(
              children: [
                CircleAvatar(
                  radius: 20.w,
                  backgroundImage: review['user_avatar'] != null
                      ? CachedNetworkImageProvider(review['user_avatar'] as String)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['user_name'] ?? 'Anonymous',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final rating = review['rating'] as double? ?? 0;
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 16.w,
                              color: Colors.amber,
                            );
                          }),
                          SizedBox(width: 8.w),
                          Text(
                            '${review['rating']?.toStringAsFixed(1) ?? "0.0"}',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review['created_at']),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (review['comment'] != null && (review['comment'] as String).isNotEmpty)
              Text(
                review['comment'] as String,
                style: TextStyle(fontSize: 14.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Row(
      children: [
        if (bookThumbnail != null)
          CachedNetworkImage(
            imageUrl: bookThumbnail!,
            width: 40.w,
            height: 60.h,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 40.w,
              height: 60.h,
              color: Colors.grey[300],
            ),
            errorWidget: (context, url, error) => Container(
              width: 40.w,
              height: 60.h,
              color: Colors.grey[300],
              child: Icon(Icons.book, size: 24.w),
            ),
          ),
        SizedBox(width: bookThumbnail != null ? 12.w : 0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookTitle ?? 'Unknown Book',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (bookAuthors != null && bookAuthors!.isNotEmpty)
                Text(
                  bookAuthors!.join(', '),
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final DateTime dateTime = date is DateTime ? date : DateTime.parse(date.toString());
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}