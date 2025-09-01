import 'package:book_app/features/home/data/models/book_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_book_model.dart';

class LibraryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<UserBook>> fetchBooksByStatus(String status) async {
    try {
      final response = await _client
          .from('user_books')
          .select('*, books(*)')
          .eq('status', status)
          .order('created_at', ascending: false);



      print("📚 Supabase response: $response");

      return response.map((json) {
        try {
          print("Supabase books object: ${json['books']}");

          return UserBook.fromJson(json);

        } catch (e) {
          print("❌ Failed to parse UserBook: $e");
          return null;
        }
      }).whereType<UserBook>().toList();
    } catch (e) {
      print("❌ Error in fetchBooksByStatus: $e");
      rethrow;
    }
  }


  Future<List<UserBook>> fetchAllBooks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final response = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId) // ✅ Filter by current user
        .order('created_at', ascending: false);

    print("📚 Supabase response: $response");

    return response.map((json) {
      try {
        print("Supabase books object: ${json['books']}");

        return UserBook.fromJson(json);
      } catch (e) {
        print("❌ Failed to parse UserBook: $e");
        return null;
      }
    }).whereType<UserBook>().toList();
  }





  Future<void> saveBookStatus({
    required String userId,
    required String bookId,
    required String status,
    required Items book,
    double progress = 0.0,
  }) async {
    print("📦 Upserting: userId=$userId, bookId=$bookId, status=$status, progress=$progress");

    await _client.from('books').upsert({
      'book_id': book.id,
      'title': book.volumeInfo?.title,
      'authors': book.volumeInfo?.authors,
      'thumbnail_url': book.volumeInfo?.imageLinks?.thumbnail,
      'published_date': book.volumeInfo?.publishedDate,
      'page_count': book.volumeInfo?.pageCount,
      'categories': book.volumeInfo?.categories,
      'description': book.volumeInfo?.description,
      'average_rating': book.volumeInfo?.averageRating,
      'ratings_count': book.volumeInfo?.ratingsCount,
    });
    try{
      final response = await _client.from('user_books').upsert({
        'user_id': userId,
        'book_id': bookId,
        'status': status,
        'progress': progress,
        'updated_date': DateTime.now().toIso8601String(),
      },onConflict:'user_id,book_id');
      if (response == null) {
        print("❌ Supabase response is null");
      } else {
        print("✅ Supabase upsert success: $response");
      }
    }catch (e) {
      print("🔥 Supabase upsert failed: $e");
    }

  }

  Future<void> updateProgress({
    required String userId,
    required String bookId,
    required double progress,
  }) async {
    await _client.from('user_books').update({
      'progress': progress,
      'updated_date': DateTime.now().toIso8601String(),
    }).match({
      'user_id': userId,
      'book_id': bookId,
    });
  }

  Future<void> markAsFinished({
    required String userId,
    required String bookId,
    required Items book,
  }) async {
    await saveBookStatus(userId: userId, bookId: bookId, status: 'finished', progress: 100, book: book,);
  }

  Future<UserBook?> updateBookCategory({
    required String userId,
    required String bookId,
    required String category,
  }) async {
    try {
      final response = await _client
          .from('user_books')
          .update({
        'status': category,
        'updated_date': DateTime.now().toIso8601String(),
      })
          .match({
        'user_id': userId,
        'book_id': bookId,
      })
          .select()
          .single();

      if (response != null) {
        print("✅ Category updated: $response");
        return UserBook.fromJson(response);
      } else {
        print("❌ No response from Supabase");
        return null;
      }
    } catch (e) {
      print("🔥 Failed to update category: $e");
      return null;
    }
  }


  Future<void> addBookToList(String bookId, String listId) async {
    await _client.from('list_books').insert({
      'list_id': listId,
      'book_id': bookId,
    });
  }

}
