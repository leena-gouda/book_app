import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../home/data/models/book_model.dart';

class ReadingProgressBar extends StatefulWidget {
  final double currentProgress;
  final Function(double) onProgressChanged;
  final Items book;
  final String bookId;

  const ReadingProgressBar({
    Key? key,
    required this.currentProgress,
    required this.onProgressChanged,
    required this.book,
    required this.bookId,
  }) : super(key: key);

  @override
  _ReadingProgressBarState createState() => _ReadingProgressBarState();
}

class _ReadingProgressBarState extends State<ReadingProgressBar> {
  late double _currentProgress;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.currentProgress;
  }

  @override
  void didUpdateWidget(ReadingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when parent widget provides new progress value
    if (oldWidget.currentProgress != widget.currentProgress) {
      setState(() {
        _currentProgress = widget.currentProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reading Progress",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_currentProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ]
        ),
            SizedBox(height: 12.h),
            Container(
                height: 24.h,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8.h,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 12.w,
                      disabledThumbRadius: 12.w,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: 6.w,
                    ),
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _currentProgress.clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    onChanged: (newProgress) {
                      setState(() {
                        _currentProgress = newProgress;
                      });
                    },
                    onChangeEnd: (finalProgress) {
                      // Only update the actual progress when user stops sliding
                      widget.onProgressChanged(finalProgress);
                    },
                  ),
                )
            ),
            SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "0 pages",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            Text(
              "${widget.book.volumeInfo?.pageCount} pages",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        )
      ],
    );
  }
}