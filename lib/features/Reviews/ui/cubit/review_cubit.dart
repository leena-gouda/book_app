import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repo/review_repo.dart';

class ReviewCubit extends Cubit<Stream<List<Map<String, dynamic>>>> {
  final ReviewRepository _repository;
  String? _currentBookId;
  StreamSubscription? _subscription;

  ReviewCubit(this._repository) : super(Stream.value([]));

  void loadReviews(String bookId) {
    _currentBookId = bookId;
    print('Loading reviews for book: $bookId');

    // Cancel any existing subscription
    _subscription?.cancel();

    final stream = _repository.getReviews(bookId);
    emit(stream);

    // Listen to the stream to handle errors
    _subscription = stream.listen(
          (data) {
        print('Cubit received ${data.length} reviews');
      },
      onError: (error) {
        print('Cubit stream error: $error');
        // Emit an empty stream on error
        emit(Stream.value([]));
      },
    );
  }

  Future<void> addReview({
    required String bookId,
    required double rating,
    required String comment,
  }) async {
    try {
      print('Starting review submission...');
      await _repository.submitReview(
        bookId: bookId,
        rating: rating,
        comment: comment,
      );
      print('Review submitted successfully');
      if (_currentBookId == bookId) {
        loadReviews(bookId); // This will re-emit the stream
      }
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}