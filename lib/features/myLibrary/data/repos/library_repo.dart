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
    double? progress,
  }) async {
    print("📦 Upserting: userId=$userId, bookId=$bookId, status=$status, progress=$progress");

    try{
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
        'created_at': DateTime.now().toIso8601String(),
      });

      final response = await _client.from('user_books').upsert({
        'user_id': userId,
        'book_id': bookId,
        'status': status,
        'progress': progress ?? 0.0,
        'updated_date': DateTime.now().toIso8601String(),
      },onConflict:'user_id,book_id').select();

      if (response == null) {
        print("❌ Supabase response is null");
      } else {
        print("✅ Supabase upsert success: $response");
      }
    }catch (e) {
      print("🔥 Supabase upsert failed: $e");
      rethrow; // Important: rethrow to let cubit handle the error
    }

  }

  Future<bool> doesUserBookExist(String userId, String bookId) async {
    try {
      final response = await _client
          .from('user_books')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print("Error checking user book existence: $e");
      return false;
    }
  }

  // In LibraryRepository
  Future<void> fixMissingUserBooks() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final userBookIds = _client
          .from('user_books')
          .select('book_id')
          .eq('user_id', userId);

      final orphanedBooks = await _client
          .from('books')
          .select('book_id')
          .filter('book_id', 'not.in', userBookIds);

      for (final book in orphanedBooks) {
        await _client.from('user_books').insert({
          'user_id': userId,
          'book_id': book['id'],
          'status': 'none',
          'progress': 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print("✅ Fixed orphaned book: ${book['id']}");
      }
    } catch (e) {
      print("Error fixing orphaned books: $e");
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


  Future<void> addBookToList(String bookId, int listId) async {
    await _client.from('list_books').insert({
      'list_id': listId,
      'book_id': bookId,
    });
  }

  Future<void> updateProgressAndStatus({
    required String userId,
    required String bookId,
    required double progress,
    required String status,
  }) async {
    await _client.from('user_books').update({
      'progress': progress,
      'status': status,
      'updated_date': DateTime.now().toIso8601String(),
    }).match({
      'user_id': userId,
      'book_id': bookId,
    });
  }

}
