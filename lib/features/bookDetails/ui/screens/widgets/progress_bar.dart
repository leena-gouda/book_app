import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../home/data/models/book_model.dart';
import '../../../../myLibrary/ui/cubit/my_library_cubit.dart';

class ReadingProgressBar extends StatelessWidget {
  final double currentProgress;
  final ValueChanged<double> onProgressChanged;

  final Items book;
  final bookId;
  const ReadingProgressBar({
    super.key,
    required this.currentProgress,
    required this.onProgressChanged, required this.book, this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    print("Building ReadingProgressBar for book: ${book.volumeInfo?.title}");
    assert(book.volumeInfo?.title != null, 'Book details are missing for bookId: ${book.id}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Make it stretch full width
      children: [
        // Header row with title and percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between title and %
          children: [
            Text(
              "Reading Progress",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(currentProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Thicker and full-width slider
        Container(
          height: 24.h, // Make the track area thicker
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8.h, // Thicker track
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12.w, // Larger thumb
                disabledThumbRadius: 12.w,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 6.w, // Larger overlay
              ),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withOpacity(0.2),
            ),
            child: Slider(
              value: currentProgress,
              min: 0.0,
              max: 1.0,
              onChanged: onProgressChanged,
              onChangeEnd: (newProgress) {
                if (newProgress != currentProgress) {
                  context.read<LibraryCubit>().setBookStatus(
                    bookId,
                    'reading',
                    progress: newProgress,
                    book: book,
                  );
                }

                print("📤 Auto-saving progress: $newProgress");
              },
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // Percentage labels aligned with slider edges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 pages',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${book.volumeInfo?.pageCount} pages',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}