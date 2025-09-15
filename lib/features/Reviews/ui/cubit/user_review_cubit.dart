import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/review_repo.dart';

part 'review_state.dart';

class UserReviewsCubit extends Cubit<UserReviewsState> {
  final ReviewRepository repository;

  UserReviewsCubit(this.repository) : super(UserReviewsInitial());

  Future<void> loadUserReviews() async {
    emit(UserReviewsLoading());
    try {
      final reviews = await repository.getUserReviews();
      emit(UserReviewsLoaded(reviews: reviews));
    } catch (e) {
      emit(UserReviewsError('Failed to load reviews: $e'));
    }
  }
}