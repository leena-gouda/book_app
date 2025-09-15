import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitReview({
    required String bookId,
    required double rating,
    required String comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    print('Submitting review for user: ${user.id}, book: $bookId');

    try {
      final userName = user.email?.split('@').first ?? 'Anonymous';

      final existingReview = await _client
          .from('reviews')
          .select('rating')
          .eq('book_id', bookId)
          .eq('user_id', user.id)
          .maybeSingle();

      final double? existingRating = existingReview?['rating'] != null
          ? (existingReview!['rating'] as num).toDouble()
          : null;

      // Use UPSERT to handle both insert and update in one operation
      print('Using upsert for review...');
      await _client
          .from('reviews')
          .upsert({
        'book_id': bookId,
        'user_id': user.id,
        'user_name': userName,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      },
          onConflict: 'book_id,user_id' // This tells Supabase which unique constraint to use
      );

      print('Review upserted successfully');

      await _updateBookRatings(bookId, rating, existingRating);


    } on PostgrestException catch (e) {
      print('Postgrest error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<void> _updateBookRatings(String bookId, double newRating, double? existingRating) async {
    // Get current book ratings
    final bookResponse = await _client
        .from('books')
        .select('average_rating, ratings_count')
        .eq('book_id', bookId)
        .single();

    final double currentAverage = bookResponse['average_rating'] != null
        ? (bookResponse['average_rating'] as num).toDouble()
        : 0.0;

    final int currentCount = bookResponse['ratings_count'] != null
        ? (bookResponse['ratings_count'] as int)
        : 0;

    double newAverage;
    int newCount;

    if (existingRating == null) {
      // This is a new review
      newCount = currentCount + 1;
      newAverage = ((currentAverage * currentCount) + newRating) / newCount;
    } else {
      // This is an updated review
      newCount = currentCount; // Count stays the same
      newAverage = ((currentAverage * currentCount) - existingRating + newRating) / currentCount;
    }

    // Update the book with new ratings
    await _client
        .from('books')
        .update({
      'average_rating': newAverage,
      'ratings_count': newCount,
    })
        .eq('book_id', bookId);

    print('Updated book ratings: average=$newAverage, count=$newCount');
  }

  Stream<List<Map<String, dynamic>>> getReviews(String bookId) {
    print('Creating stream for book: $bookId');

    try {
      return _client
          .from('reviews')
          .stream(primaryKey: ['id'])
          .eq('book_id', bookId)
          .order('created_at', ascending: false)
          .map((data) {
        print('Stream received data: ${data.length} reviews');
        return data;
      })
          .handleError((error, stackTrace) {
        print('Stream error for book $bookId: $error');
        return []; // Return empty list on error
      });
    } catch (e) {
      print('Error creating stream: $e');
      return Stream.value([]); // Return empty stream on creation error
    }
  }

  // Get all reviews by current user
  Future<List<Map<String, dynamic>>> getUserReviews() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('reviews')
          .select('''
            *,
            books:book_id (
              book_id,
              title,
              authors,
              thumbnail_url
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

}
