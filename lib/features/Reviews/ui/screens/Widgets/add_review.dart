import 'package:book_app/features/Reviews/ui/cubit/review_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';

class AddReviewBottomSheetContent extends StatelessWidget {
  final String bookId;

  const AddReviewBottomSheetContent({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    // Move state variables outside the StatefulBuilder builder function
    double rating = 0.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    void submitReview(Function(void Function()) setState) async {
      print('Submitting review for book: $bookId');
      if (rating == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a rating")),
        );
        return;
      }
      if (commentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please write a review")),
        );
        return;
      }
      setState(() {
        isSubmitting = true;
      });

      try {
        await context.read<ReviewCubit>().addReview(
          bookId: bookId,
          rating: rating,
          comment: commentController.text.trim(),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Review submitted successfully!"))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to submit review: $e"))
        );
      } finally {
        setState(() {
          isSubmitting = false;
        });
      }
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 16.h
      ),
      child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Add Review", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(CupertinoIcons.xmark)
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Text("Your rating", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
                ),
                SizedBox(height: 16.h), // Changed from .sp to .h for consistency
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                        child: Icon(
                          index < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 32.sp,
                          color: index < rating ? Colors.amber : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  "Your Review",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Share your thoughts about this book...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    contentPadding: EdgeInsets.all(16.w),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(12.r),
                    onPressed: isSubmitting ? null : () => submitReview(setState),
                    child: isSubmitting
                        ? CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                      "Submit Review",
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            );
          }
      ),
    );
  }
}