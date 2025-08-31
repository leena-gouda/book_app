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

    } on PostgrestException catch (e) {
      print('Postgrest error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Failed to submit review: $e');
    }
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
}
