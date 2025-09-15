part of 'user_review_cubit.dart';


@immutable
abstract class UserReviewsState {}

class UserReviewsInitial extends UserReviewsState {}

class UserReviewsLoading extends UserReviewsState {}

class UserReviewsLoaded extends UserReviewsState {
  final List<Map<String, dynamic>> reviews;

  UserReviewsLoaded({required this.reviews});
}

class UserReviewsError extends UserReviewsState {
  final String message;

  UserReviewsError(this.message);
}