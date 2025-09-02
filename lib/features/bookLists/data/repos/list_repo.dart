import 'package:book_app/features/home/data/models/book_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_lists.dart';

class ListRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all custom lists for the current user
  Future<List<CustomList>> getCustomLists() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('custom_lists')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Handle case where no lists exist
      if (response.isEmpty) {
        print('📭 No custom lists found for user ${user.id}');
        return [];
      }

      // Get book counts for each list
      final listsWithCounts = await Future.wait(
          (response as List).map((listData) async {
            final countResponse = await _client
                .from('list_books')
                .select()
                .eq('list_id', listData['id']);

            final bookCount = countResponse.length;

            return CustomList.fromJson({
              ...listData,
              'book_count': bookCount,
            });
          }).toList()
      );

      return listsWithCounts;
    } catch (e) {
      print('Error fetching lists: $e');
      // Return empty list instead of throwing error for "no lists" case
      if (e.toString().contains('0 rows') || e.toString().contains('single JSON object')) {
        return [];
      }
      rethrow;
    }
  }
  // Create a new list
  Future<CustomList> createList(String name) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('custom_lists')
          .insert({
        'name': name,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .maybeSingle(); // Use maybeSingle instead of single

      // Handle case where insert might not return a response
      if (response == null) {
        throw Exception('Failed to create list: no response from server');
      }

      return CustomList.fromJson({...response, 'book_count': 0});
    } catch (e) {
      print('Error creating list: $e');
      rethrow;
    }
  }
  // Add a book to a list - FIXED
  Future<void> addBookToList(int listId, String bookId, Items book) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First ensure the book exists in the books table
      final bookResponse = await _client
          .from('books')
          .select()
          .eq('id', bookId)
          .maybeSingle();

      if (bookResponse == null) {
        // Insert book into books table first
        await _client
            .from('books')
            .insert({
          'id': bookId,
          'title': book.volumeInfo?.title,
          'authors': book.volumeInfo?.authors,
          'description': book.volumeInfo?.description,
          'page_count': book.volumeInfo?.pageCount,
          'categories': book.volumeInfo?.categories,
          'average_rating': book.volumeInfo?.averageRating,
          'ratings_count': book.volumeInfo?.ratingsCount,
          'thumbnail_url': book.volumeInfo?.imageLinks?.thumbnail,
          // Add other book fields as needed
        });
      }

      // Then ensure the user_book entry exists
      final userBookResponse = await _client
          .from('user_books')
          .select('id')
          .eq('book_id', bookId)
          .eq('user_id', user.id)
          .maybeSingle();

      int userBookId;

      if (userBookResponse == null) {
        // Create new user_book entry
        final newUserBook = await _client
            .from('user_books')
            .insert({
          'book_id': bookId,
          'user_id': user.id,
          'status': 'to_read',
          'progress': 0,
        })
            .select('id')
            .single();
        userBookId = newUserBook['id'] as int;
      } else {
        userBookId = userBookResponse['id'] as int;
      }

      // Then add to list using the integer user_book_id
      await _client.from('list_books').insert({
        'list_id': listId,
        'user_book_id': userBookId,
        'added_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding book to list: $e');
      rethrow;
    }
  }

  // Remove a book from a list - FIXED
  Future<void> removeBookFromList(int listId, String bookId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First get the user_book_id
      final userBookResponse = await _client
          .from('user_books')
          .select('id')
          .eq('book_id', bookId)
          .eq('user_id', user.id)
          .single();

      final userBookId = userBookResponse['id'] as int;

      await _client
          .from('list_books')
          .delete()
          .eq('list_id', listId)
          .eq('user_book_id', userBookId);
    } catch (e) {
      print('Error removing book from list: $e');
      rethrow;
    }
  }

  Future<List<Items>> getBooksInList(int listId) async {
    try {
      final response = await _client
          .from('list_books')
          .select('''
          user_books (
            book_id,
            books (*)
          )
        ''')
          .eq('list_id', listId);

      print('📋 Full join response: ${response.length} entries');

      // Handle empty list case
      if (response.isEmpty) {
        print('📭 List $listId is empty');
        return [];
      }

      List<Items> books = [];
      for (var item in response) {
        if (item['user_books'] != null) {
          final userBookData = item['user_books'] as Map<String, dynamic>;

          // Check if books data exists
          if (userBookData['books'] != null) {
            final bookData = userBookData['books'] as Map<String, dynamic>;
            print('📖 Book data: $bookData');

            // Convert the book data to your Items model
            final book = Items.fromSupabaseJson(bookData);
            books.add(book);
          } else {
            // If books data doesn't exist, create a basic Items object
            final book = Items(
              id: userBookData['book_id']?.toString(),
              volumeInfo: VolumeInfo(
                title: 'Unknown Book',
                authors: [],
              ),
            );
            books.add(book);
          }
        }
      }

      print('✅ Successfully parsed ${books.length} books');
      return books;
    } catch (e) {
      print('❌ Error in getBooksInList: $e');
      // Return empty list instead of throwing error for empty lists
      if (e.toString().contains('0 rows') || e.toString().contains('empty')) {
        return [];
      }
      rethrow;
    }
  }
  Future<void> deleteList(int listId) async {
    try {
      // First delete all books in the list
      await _client
          .from('list_books')
          .delete()
          .eq('list_id', listId);

      // Then delete the list itself
      await _client
          .from('custom_lists')
          .delete()
          .eq('id', listId);
    } catch (e) {
      print('Error deleting list: $e');
      rethrow;
    }
  }

  // Update list name
  Future<CustomList> updateListName(int listId, String newName) async {
    try {
      final response = await _client
          .from('custom_lists')
          .update({'name': newName})
          .eq('id', listId)
          .select()
          .maybeSingle(); // Use maybeSingle

      if (response == null) {
        throw Exception('List not found or update failed');
      }

      // Get updated book count
      final countResponse = await _client
          .from('list_books')
          .select()
          .eq('list_id', listId);

      final bookCount = countResponse.length;

      return CustomList.fromJson({
        ...response,
        'book_count': bookCount,
      });
    } catch (e) {
      print('Error updating list name: $e');
      rethrow;
    }
  }
  // Test method
  Future<void> testListOperations() async {
    try {
      final lists = await getCustomLists();
      print('📋 Lists found: ${lists.length}');

      for (var list in lists) {
        print('List: ${list.name}, ID: ${list.id}, Book count: ${list.bookCount}');

        // Try to get books
        final books = await getBooksInList(list.id);
        print('Books in list: ${books.length}');
      }
    } catch (e) {
      print('Test error: $e');
    }
  }
}