import 'package:book_app/features/Reviews/ui/screens/Widgets/review_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../bookDetails/ui/screens/widgets/custom_button.dart';
import '../../cubit/review_cubit.dart';
import '../reviews_screen.dart';
import 'add_review.dart';

class CustomReviewSection extends StatelessWidget {
  final String bookId;

   CustomReviewSection({super.key, required this.bookId}){
    print('CustomReviewSection created with bookId: $bookId');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewCubit, Stream<List<Map<String, dynamic>>>>(
      builder: (context, reviewsStream) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: reviewsStream,
          builder: (context, snapshot) {
            print('StreamBuilder rebuilt - ConnectionState: ${snapshot.connectionState}');
            print('StreamBuilder has data: ${snapshot.hasData}');
            print('StreamBuilder data length: ${snapshot.data?.length ?? 0}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading reviews',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14.sp,
                  ),
                ),
              );
            }

            final reviews = snapshot.data ?? [];

            final limitedReviews = reviews.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header with "View All" button
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      CustButton(text: "Add Review", onPressed:() => _addReview(context), margin: EdgeInsets.symmetric(),backgroundColor: CupertinoColors.activeBlue,borderRadius: 12.r,height: 30.h,iconData: CupertinoIcons.plus,iconColor: AppColor.white,),
                      if (reviews.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _navigateToAllReviews(context, reviews),
                          child: Text(
                            'See All (${reviews.length})',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (reviews.isEmpty)
                  Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                // Reviews list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedReviews.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    return ReviewCard(review: limitedReviews[index]);
                  },
                ),

                // "See More" button for when there are more than 3 reviews
                if (reviews.length > 3)
                  Center(
                    child: CupertinoButton(
                      onPressed: () => _navigateToAllReviews(context, reviews),
                      child: Text(
                        'See More Reviews',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToAllReviews(BuildContext context, List<Map<String, dynamic>> reviews) {
    Navigator.pushNamed(
      context,
      Routes.reviewsScreen,
      arguments: {
        'bookId': bookId,
        'reviews': reviews,
      },
    );
  }

  void _addReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
        builder: (context) {
          return AddReviewBottomSheetContent(bookId: bookId);
        }
    );
  }

}


