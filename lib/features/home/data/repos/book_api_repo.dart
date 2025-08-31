import 'package:book_app/core/constants/endpoint_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/network/dio_client.dart';
import '../models/book_model.dart';

class BooksApiRepo {
  final DioClient _dioClient;
  static const String _apiKey = 'AIzaSyBMV9LFa55r2XpxTbrPrOMcA5Q05cSa-uM';

  final Map<String, List<Items>> _dataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 30);

  BooksApiRepo(this._dioClient);

  // 1. SEARCH FOR BOOKS
  Future<List<Items>> searchBooks(String query) async {
    return _cachedApiCall(
      'search_$query',
          () async {
        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": query,
            "maxResults": "25",
            "key": _apiKey,
          },
        );

        final items = response.data['items'] as List?;
        return items?.map((item) => Items.fromJson(item)).toList() ?? [];
      },
    );
  }

  // 2. GET BOOKS BY GENRE
  Future<List<Items>> getBooksByGenre(String genre) async {
    return _cachedApiCall(
      'genre_$genre',
          () async {
        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": "subject:$genre",
            "orderBy": "relevance",
            "maxResults": "25",
            "key": _apiKey,
          },
        );

        final items = response.data['items'] as List?;
        return items?.map((item) => Items.fromJson(item)).toList() ?? [];
      },
    );
  }

  // 3. GET TRENDING BOOKS
  Future<List<Items>> getTrendingBooks() async {
    return _cachedApiCall(
      'trending_books',
          () async {
        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": "subject:fiction",
            "orderBy": "newest",
            "maxResults": "20",
            "key": _apiKey,
          },
        );

        final items = response.data['items'] as List?;
        return items?.map((item) => Items.fromJson(item)).toList() ?? [];
      },
    );
  }

  // 4. GET NEW RELEASES
  Future<List<Items>> getNewReleases() async {
    return _cachedApiCall(
      'new_releases',
          () async {
        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": "subject:fiction",
            "orderBy": "newest",
            "maxResults": "30",
            "key": _apiKey,
          },
        );

        final items = response.data['items'] as List?;
        return items?.map((item) => Items.fromJson(item)).toList() ?? [];
      },
    );
  }

  // 5. GET BOOKS BY ISBN (NEW - Much more reliable than title search)
  Future<List<Items>> getBooksByISBNs(List<String> isbns) async {
    try {
      if (isbns.isEmpty) return [];

      final limitedIsbns = isbns.take(3).toList();
      debugPrint("Searching for ${limitedIsbns.length} ISBNs: $limitedIsbns");

      final query = limitedIsbns.map((isbn) => 'isbn:$isbn').join(' OR ');

      final response = await _dioClient.get(
        EndpointConstants.volumes,
        queryParameters: {
          "q": query,
          "maxResults": "10",
          "key": _apiKey,
        },
      ).timeout(Duration(seconds: 30)); // Increased timeout

      final items = response.data['items'] as List?;
      return items?.map((item) => Items.fromJson(item)).toList() ?? [];

    } catch (e) {
      debugPrint("ISBN search error: $e");
      return [];
    }
  }

  Future<List<Items>> getBooksFromTitles(List<String> titles) async {
    if (titles.isEmpty) return [];

    return _cachedApiCall(
      'titles_${titles.join('_')}',
          () async {
        // Use EXACT title matching with quotes for better accuracy
        final exactTitleQueries = titles.map((title) => 'intitle:"$title"').join(' OR ');

        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": exactTitleQueries,
            "maxResults": "10", // Reduced to get more relevant results
            "orderBy": "relevance",
            "key": _apiKey,
          },
        ).timeout(Duration(seconds: 15));

        final items = response.data['items'] as List?;

        // Filter for more relevant results
        final relevantBooks = items?.map((item) => Items.fromJson(item)).toList() ?? [];

        // Additional filtering by checking if titles actually match
        final lowercaseSearchTitles = titles.map((t) => t.toLowerCase()).toList();
        return relevantBooks.where((book) {
          final bookTitle = book.volumeInfo?.title?.toLowerCase() ?? '';
          return lowercaseSearchTitles.any((searchTitle) =>
              bookTitle.contains(searchTitle.toLowerCase()));
        }).toList();
      },
    );
  }
  // 7. INDIVIDUAL TITLE SEARCH (Fallback - use sparingly)
  Future<List<Items>> getBooksFromTitlesIndividual(List<String> titles) async {
    try {
      List<Items> results = [];
      final limitedTitles = titles.take(5).toList(); // Limit to 5 titles

      for (final title in limitedTitles) {
        debugPrint("Fetching books for title: $title");

        // Add delay to avoid rate limiting
        await Future.delayed(Duration(milliseconds: 200));

        final response = await _dioClient.get(
          EndpointConstants.volumes,
          queryParameters: {
            "q": 'intitle:"$title"',
            "maxResults": "5",
            "key": _apiKey,
          },
        );

        final items = response.data['items'] as List?;
        if (items != null) {
          final books = items.map((json) => Items.fromJson(json)).toList();
          results.addAll(books);
        } else {
          debugPrint("No items found for title: $title");
        }

        // Break early if we have enough results
        if (results.length >= 20) break;
      }
      return results;
    } catch (e, stack) {
      debugPrint("Error in getBooksFromTitlesIndividual: $e");
      debugPrint("Stack trace: $stack");
      return [];
    }
  }

  // UNIVERSAL CACHED API CALL METHOD
  Future<List<Items>> _cachedApiCall(
      String cacheKey,
      Future<List<Items>> Function() apiCall,
      ) async {
    try {
      // Check cache first
      if (_isCacheValid(cacheKey)) {
        debugPrint("Cache hit for: $cacheKey");
        return _dataCache[cacheKey]!;
      }

      debugPrint("Cache miss for: $cacheKey, making API call");
      final result = await apiCall();

      // Update cache
      _dataCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint("Fetched ${result.length} items for: $cacheKey");
      return result;
    } catch (e) {
      debugPrint("API call failed for $cacheKey: $e");
      rethrow;
    }
  }

  bool _isCacheValid(String cacheKey) {
    final cachedData = _dataCache[cacheKey];
    final cacheTime = _cacheTimestamps[cacheKey];

    if (cachedData == null || cacheTime == null) return false;

    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  // Clear cache
  void clearCache() {
    _dataCache.clear();
    _cacheTimestamps.clear();
    debugPrint("Cache cleared");
  }

  Future<List<Items>> getMixedBooks({String? genre, int limit = 10}) async {
    final List<Items> allBooks = [];

    try {
      // Source 1: Google Books by genre
      final googleBooks = await getBooksByGenre(genre ?? "fiction");
      allBooks.addAll(googleBooks.take(limit ~/ 2));

      // Source 2: Google Books new releases
      final newReleases = await getNewReleases();
      allBooks.addAll(newReleases.take(limit ~/ 2));

      // Remove duplicates
      return _removeDuplicateBooks(allBooks).take(limit).toList();

    } catch (e) {
      debugPrint("Mixed books error: $e");
      return await getTrendingBooks(); // Fallback
    }
  }

  // ENHANCED NEW RELEASES: Mix of Google Books and publication date filtering
  Future<List<Items>> getEnhancedNewReleases() async {
    try {
      final allBooks = await getNewReleases();

      // Filter for actually recent books (last 6 months)
      final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
      final recentBooks = allBooks.where((book) {
        final dateStr = book.volumeInfo?.publishedDate;
        if (dateStr == null) return false;

        try {
          final parsedDate = DateTime.parse(dateStr);
          return parsedDate.isAfter(sixMonthsAgo);
        } catch (_) {
          return false;
        }
      }).toList();

      return recentBooks.take(8).toList();

    } catch (e) {
      debugPrint("Enhanced new releases error: $e");
      return await getNewReleases(); // Fallback to basic
    }
  }

  // ENHANCED TRENDING: Mix of Google Books and popularity metrics
  Future<List<Items>> getEnhancedTrendingBooks() async {
    try {
      final allBooks = await getTrendingBooks();

      // Sort by rating and review count for better trending selection
      final sortedBooks = allBooks.where((book) {
        return book.volumeInfo?.averageRating != null &&
            book.volumeInfo?.ratingsCount != null;
      }).toList()
        ..sort((a, b) {
          final aRating = a.volumeInfo?.averageRating ?? 0;
          final bRating = b.volumeInfo?.averageRating ?? 0;
          final aCount = a.volumeInfo?.ratingsCount ?? 0;
          final bCount = b.volumeInfo?.ratingsCount ?? 0;

          // Prioritize books with both high rating and many reviews
          return ((bRating * bCount) - (aRating * aCount)).toInt();
        });

      return sortedBooks.take(10).toList();

    } catch (e) {
      debugPrint("Enhanced trending error: $e");
      return await getTrendingBooks(); // Fallback to basic
    }
  }

  // Helper to remove duplicate books
  List<Items> _removeDuplicateBooks(List<Items> books) {
    final seenIds = <String>{};
    return books.where((book) {
      if (book.id != null && !seenIds.contains(book.id!)) {
        seenIds.add(book.id!);
        return true;
      }
      return false;
    }).toList();
  }
}