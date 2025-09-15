// features/reviews/ui/screens/user_reviews_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cubit/user_review_cubit.dart';
import '../../data/repo/review_repo.dart';
import 'Widgets/review_card.dart';

class UserReviewsScreen extends StatelessWidget {
  const UserReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: BlocBuilder<UserReviewsCubit, UserReviewsState>(
        builder: (context, state) {
          if (state is UserReviewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserReviewsError) {
            return Center(child: Text(state.message));
          }

          if (state is UserReviewsLoaded) {
            return _buildReviewsList(context, state.reviews);
          }

          return const Center(child: Text('No reviews yet'));
        },
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 64.w, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start reviewing books to see them here!',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final review = reviews[index];
        final book = review['books'] as Map<String, dynamic>? ?? {};

        return ReviewCard(
          review: review,
          showBookInfo: true,
          bookTitle: book['title'] ?? 'Unknown Book',
          bookAuthors: (book['authors'] as List<dynamic>?)?.cast<String>() ?? [],
          bookThumbnail: book['thumbnail_url'],
        );
      },
    );
  }
}