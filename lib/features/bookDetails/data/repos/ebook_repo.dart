import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../../core/network/dio_client.dart';

class EBookRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final DioClient _dioClient = DioClient(); // Use your Dio client

  Future<String?> getEbookDownloadUrl(String bookId) async {
    try {
      // Get the webReaderLink from Google Books API directly
      final googleBooksData = await _fetchGoogleBooksData(bookId);
      if (googleBooksData != null &&
          googleBooksData['accessInfo'] != null &&
          googleBooksData['accessInfo']['webReaderLink'] != null) {
        return googleBooksData['accessInfo']['webReaderLink'] as String;
      }

      // Fallback to generic Google Books URL
      return 'https://play.google.com/books/reader?id=$bookId';
    } catch (e) {
      print('Error getting eBook download URL: $e');
      return 'https://books.google.com/books?id=$bookId';
    }
  }

  Future<Map<String, dynamic>?> _fetchGoogleBooksData(String bookId) async {
    try {
      final response = await _dioClient.get(
        'https://www.googleapis.com/books/v1/volumes/$bookId',
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error fetching Google Books data with Dio: $e');
      return null;
    }
  }

  Future<String?> downloadEpub(String bookId) async {
    try {
      final details = await getEbookDetails(bookId);
      return details['epubDownloadLink'] as String?;
    } catch (e) {
      print('Error getting EPUB download link: $e');
      return null;
    }
  }

  Future<String?> downloadPdf(String bookId) async {
    try {
      final details = await getEbookDetails(bookId);
      return details['pdfDownloadLink'] as String?;
    } catch (e) {
      print('Error getting PDF download link: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getEbookDetails(String bookId) async {
    try {
      // First try to get basic book info from your database
      Map<String, dynamic>? dbBookData;
      try {
        final response = await _client
            .from('books')
            .select('title, average_rating, page_count, categories, description')
            .eq('book_id', bookId)
            .maybeSingle(); // Use maybeSingle instead of single to handle empty results

        dbBookData = response;
      } catch (e) {
        print('Book not found in local database: $e');
        // Continue without local data
      }

      // Fetch Google Books data for more details
      final googleBooksData = await _fetchGoogleBooksData(bookId);

      // Check if eBook is available from Google Books
      bool isEbookAvailable = false;
      bool isEpubAvailable = false;
      bool isPdfAvailable = false;
      String? buyLink;
      double price = 9.99; // Default price
      String? epubDownloadLink;
      String? pdfDownloadLink;

      if (googleBooksData != null) {
        // Check access info
        if (googleBooksData['accessInfo'] != null) {
          final accessInfo = googleBooksData['accessInfo'];
          isEbookAvailable = accessInfo['embeddable'] == true ||
              accessInfo['webReaderLink'] != null;

          if (accessInfo['epub'] != null) {
            isEpubAvailable = accessInfo['epub']['isAvailable'] == true;
            // Add download link if available
            if (accessInfo['epub']['downloadLink'] != null) {
              epubDownloadLink = accessInfo['epub']['downloadLink'] as String;
            }
          }

          if (accessInfo['pdf'] != null) {
            isPdfAvailable = accessInfo['pdf']['isAvailable'] == true;
            // Add download link if available
            if (accessInfo['pdf']['downloadLink'] != null) {
              pdfDownloadLink = accessInfo['pdf']['downloadLink'] as String;
            }
          }
        }

        // Check sale info for pricing
        if (googleBooksData['saleInfo'] != null) {
          final saleInfo = googleBooksData['saleInfo'];
          if (saleInfo['saleability'] == 'FOR_SALE' &&
              saleInfo['retailPrice'] != null) {
            final retailPrice = saleInfo['retailPrice'];
            if (retailPrice['amount'] != null) {
              // Handle both int and double values
              final amount = retailPrice['amount'];
              price = (amount as num).toDouble();
            }
            buyLink = saleInfo['buyLink'] as String?;
          } else if (saleInfo['saleability'] == 'FREE' ||
              saleInfo['saleability'] == 'PUBLIC_DOMAIN') {
            price = 0.0; // Free book
          }
        }
      }

      // If we have local database data, use it for fallback pricing
      if (dbBookData != null) {
        final rating = (dbBookData['average_rating'] as num?)?.toDouble() ?? 0.0;
        if (price == 9.99) { // Only use fallback if we didn't get price from Google
          if (rating >= 4.5) {
            price = 14.99;
          } else if (rating >= 4.0) {
            price = 12.99;
          } else if (rating >= 3.0) {
            price = 9.99;
          } else {
            price = 4.99;
          }
        }
      }

      return {
        'price': price,
        'currency': 'USD',
        'isEpubAvailable': isEpubAvailable,
        'isPdfAvailable': isPdfAvailable,
        'epubDownloadLink': epubDownloadLink, // Added this
        'pdfDownloadLink': pdfDownloadLink,    // Added this
        'isEbook': isEbookAvailable,
        'buyLink': buyLink,
        'googleBooksData': googleBooksData,
      };
    } catch (e) {
      print('Error getting eBook details: $e');
      return {
        'price': 9.99,
        'currency': 'USD',
        'isEpubAvailable': false,
        'isPdfAvailable': false,
        'epubDownloadLink': null, // Added this
        'pdfDownloadLink': null,  // Added this
        'isEbook': false,
        'buyLink': null,
        'googleBooksData': null,
      };
    }
  }

  Future<bool> checkEbookAccess(String bookId) async {
    print('🔍 Checking eBook access for: $bookId');

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      print('👤 User ID: $userId');
      // 1. First check if user already purchased this eBook
      try {
        final purchase = await _client
            .from('user_ebooks')
            .select('is_purchased, purchase_date')
            .eq('user_id', userId)
            .eq('book_id', bookId)
            .maybeSingle();

        // If purchase exists and is purchased, grant access immediately
        if (purchase != null && purchase['is_purchased'] == true) {
          print('✅ eBook access granted: User has purchased this book');
          return true;
        }
      } catch (e) {
        print('Error checking purchase status: $e');
      }

      // 2. Check if book is free from Google Books API
      final googleBooksData = await _fetchGoogleBooksData(bookId);
      if (googleBooksData != null && googleBooksData['saleInfo'] != null) {
        final saleInfo = googleBooksData['saleInfo'];
        final saleability = saleInfo['saleability'] as String?;

        if (saleability == 'FREE' || saleability == 'PUBLIC_DOMAIN') {
          print('✅ eBook access granted: Book is free');
          return true;
        }

        // If book is NOT for sale, don't show purchase option
        if (saleability == 'NOT_FOR_SALE') {
          print('❌ eBook not available for purchase');
          return false;
        }
      }

      // 3. Check local database for free book logic (optional)
      try {
        final bookDetails = await _client
            .from('books')
            .select('average_rating, categories')
            .eq('book_id', bookId)
            .maybeSingle();

        if (bookDetails != null) {
          final rating = bookDetails['average_rating'] as double? ?? 0.0;
          final categories = (bookDetails['categories'] as List<dynamic>?)?.cast<String>() ?? [];

          // Free if rating > 4.5 or if it's a classic category
          final isFree = rating > 4.5 ||
              categories.any((category) =>
              category.toLowerCase().contains('classic') ||
                  category.toLowerCase().contains('free'));

          if (isFree) {
            print('✅ eBook access granted: Free based on rating/category');
            return true;
          }
        }
      } catch (e) {
        print('Error getting book details for free check: $e');
      }

      // 4. Default: no access
      print('❌ eBook access denied: Purchase required');
      return false;

    } catch (e) {
      print('Error checking eBook access: $e');
      return false;
    }
  }

  Future<String> getBookDescriptionFromDb(String bookId) async {
    try {
      final response = await _client
          .from('books')
          .select('description')
          .eq('book_id', bookId)
          .maybeSingle(); // Use maybeSingle to handle empty results

      if (response != null) {
        return response['description'] as String? ?? 'No description available';
      }

      // If not in database, try to get from Google Books API
      final googleBooksData = await _fetchGoogleBooksData(bookId);
      if (googleBooksData != null &&
          googleBooksData['volumeInfo'] != null &&
          googleBooksData['volumeInfo']['description'] != null) {
        return _cleanHtmlDescription(googleBooksData['volumeInfo']['description'] as String);
      }

      return 'No description available';
    } catch (e) {
      print('Error getting book description: $e');
      return 'No description available';
    }
  }

  String _cleanHtmlDescription(String htmlDescription) {
    // Simple HTML tag removal
    return htmlDescription
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse multiple spaces
        .trim();
  }

  // The rest of your methods can remain the same
  Future<bool> purchaseEbook(String bookId, double price) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Ensure book exists first
      final bookExists = await _ensureBookExists(bookId);
      if (!bookExists) {
        print('Failed to ensure book exists in database');
        return false;
      }

      // Now proceed with purchase
      final now = DateTime.now().toIso8601String();

      await _client.from('user_ebooks').upsert({
        'user_id': userId,
        'book_id': bookId,
        'is_purchased': true,
        'purchase_date': now,
        'price': price,
        'current_page': 0,
        'reading_progress': 0.0,
        'status': 'to_read',
        'last_read': null,
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,book_id');

      return true;
    } catch (e) {
      print('Error purchasing eBook: $e');
      return false;
    }
  }

  Future<bool> _ensureBookExists(String bookId) async {
    try {
      // Check if book exists
      final existingBook = await _client
          .from('books')
          .select('book_id')
          .eq('book_id', bookId)
          .maybeSingle();

      if (existingBook != null) return true;

      // If not, fetch from Google Books and add it
      final googleBooksData = await _fetchGoogleBooksData(bookId);
      if (googleBooksData != null && googleBooksData['volumeInfo'] != null) {
        final volumeInfo = googleBooksData['volumeInfo'];

        await _client.from('books').upsert({
          'book_id': bookId,
          'title': volumeInfo['title'],
          'authors': volumeInfo['authors'],
          'description': volumeInfo['description'] != null
              ? _cleanHtmlDescription(volumeInfo['description'] as String)
              : '',
          'page_count': volumeInfo['pageCount'],
          'categories': volumeInfo['categories'],
          'thumbnail_url': volumeInfo['imageLinks'] != null
              ? volumeInfo['imageLinks']['thumbnail']
              : null,
          'average_rating': volumeInfo['averageRating'] ?? 0.0,
          'ratings_count': volumeInfo['ratingsCount'] ?? 0,
          'published_date': volumeInfo['publishedDate'],
          'created_at': DateTime.now().toIso8601String(),
        });

        return true;
      }

      return false;
    } catch (e) {
      print('Error ensuring book exists: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final progress = await _client
          .from('user_ebooks')
          .select('current_page, total_pages, reading_progress, status, last_read')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      return progress;
    } catch (e) {
      print('Error getting reading progress: $e');
      return null;
    }
  }

  Future<bool> updateReadingProgress(String bookId, int currentPage, double progress, String status) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('user_ebooks')
          .update({
        'current_page': currentPage,
        'reading_progress': progress,
        'status': status,
        'last_read': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId)
          .eq('book_id', bookId);

      return true;
    } catch (e) {
      print('Error updating reading progress: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserLibrary() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_ebooks')
          .select('''
            *,
            books (
              book_id,
              title,
              authors,
              thumbnail_url,
              page_count,
              average_rating,
              categories
            )
          ''')
          .eq('user_id', userId)
          .eq('is_purchased', true)
          .order('purchase_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user library: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBooksByStatus(String status) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_ebooks')
          .select('''
            *,
            books (
              book_id,
              title,
              authors,
              thumbnail_url,
              page_count,
              average_rating
            )
          ''')
          .eq('user_id', userId)
          .eq('is_purchased', true)
          .eq('status', status)
          .order('last_read', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting books by status: $e');
      return [];
    }
  }

  Future<bool> updateBookStatus(String bookId, String status) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('user_ebooks')
          .update({
        'status': status,
        'last_read': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId)
          .eq('book_id', bookId);

      return true;
    } catch (e) {
      print('Error updating book status: $e');
      return false;
    }
  }

  Future<bool> hasPurchasedEbook(String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final purchase = await _client
          .from('user_ebooks')
          .select('is_purchased')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      return purchase != null && purchase['is_purchased'] == true;
    } catch (e) {
      print('Error checking purchase status: $e');
      return false;
    }
  }

  Future<int> getReadingStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('user_ebooks')
          .select('current_page')
          .eq('user_id', userId)
          .eq('is_purchased', true);

      final totalPages = response.fold<int>(0, (sum, book) => sum + (book['current_page'] as int? ?? 0));
      return totalPages;
    } catch (e) {
      print('Error getting reading stats: $e');
      return 0;
    }
  }
}