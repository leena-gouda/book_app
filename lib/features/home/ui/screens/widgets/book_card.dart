import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../home/data/models/book_model.dart';

class BookkCard extends StatelessWidget {
  final Items book;


  const BookkCard({super.key, required this.book,});

  @override
  Widget build(BuildContext context) {
    final imageUrl = book.volumeInfo?.imageLinks?.thumbnail ?? book.volumeInfo?.imageLinks?.smallThumbnail;
    return SizedBox(
      height: 320.h,
      child:  GestureDetector(
          onTap: () {
            Navigator.pushNamed(
                context,
                Routes.bookDetailsScreen,
                arguments: {'books': book, 'bookId': book.id}
            );
          },
          child: SizedBox(
            width: 160.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover Image Container
                Container(
                  width: 160.w,
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[200],
                  ),
                  child: imageUrl != null
                    ? ClipRRect(
                       borderRadius: BorderRadius.circular(12.r),
                       child: Image.network(
                          imageUrl,
                          width: 160.w,
                          height: 200.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIcon();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                       ),
                    )
                  : _buildPlaceholderIcon(),
                ),
                SizedBox(height: 8.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Title
                    Text(
                      book.volumeInfo?.title ?? 'Unknown Title',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Author Name
                    Text(
                      book.volumeInfo?.authors?.join(', ') ?? 'Unknown Author',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Category (only show if exists)
                    if (book.volumeInfo?.categories?.isNotEmpty ?? false)
                      Text(
                        book.volumeInfo!.categories!.first,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                )

              ],
            ),
          ),
        )
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[200],
      child: Icon(
        Icons.book,
        size: 40.sp,
        color: Colors.grey[400],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reading':
        return Colors.green;
      case 'finished':
        return Colors.blue;
      case 'to_read':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'to read':
      case 'to_read':
        return 'To Read';
      case 'reading':
        return 'Reading';
      case 'finished':
        return 'Finished';
      case 'all':
        return 'All';
      default:
        return "Unknown";
    }
  }
}