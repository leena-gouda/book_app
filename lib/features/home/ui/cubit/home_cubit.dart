import 'package:book_app/features/home/data/repos/book_api_repo.dart';
import 'package:book_app/features/home/data/repos/mockrepo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../data/models/book_model.dart';
import '../../data/models/nyt_model.dart';
import '../../data/repos/nyt_books_repo.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final BooksApiRepo apiRepo;
  final NYTBooksRepo nytBooksRepo;
  final MockBooksRepo mockRepo;
  BooksApiRepo get _currentRepo => _useMockData ? mockRepo : apiRepo;

  List<Items> _trendingBooks = [];
  List<Items> _newReleases = [];
  List<Items> _noteworthyBooks = [];
  bool _useMockData = false;
  int currentGenreIndex = 0;
  bool showGenreView = false;


  // Throttling properties
  DateTime _lastApiCall = DateTime.now();
  final Duration _minCallInterval = Duration(seconds: 2);
  bool _isLoading = false;
  Timer? _searchTimer;

  final List<String> genres = [
    "fiction", "fantasy", "romance", "science fiction", "mystery",
    "thriller", "nonfiction", "biography", "history", "science"
  ];

  bool get isUsingMockData => _useMockData;

  HomeCubit({
    required this.apiRepo,
    required this.mockRepo,
    required this.nytBooksRepo
  }) : super(HomeInitial());

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _loadDataSequentially() async {
    emit(HomeLoading());

    try {
      debugPrint("Starting simplified sequential load...");

      // Load data in parallel with timeouts
      final results = await Future.wait([
        _getSimpleTrendingBooks().timeout(Duration(seconds: 20)),
        _getSimpleNewReleases().timeout(Duration(seconds: 20)),
        _getSimpleRecommendedBooks().timeout(Duration(seconds: 20)),
      ], eagerError: false);

      _trendingBooks = results[0];
      _newReleases = results[1];
      _noteworthyBooks = results[2];

      debugPrint("Loaded: ${_trendingBooks.length} trending, "
          "${_newReleases.length} new, ${_noteworthyBooks.length} recommended");

      if (_trendingBooks.isNotEmpty || _newReleases.isNotEmpty || _noteworthyBooks.isNotEmpty) {
        emit(HomeSuccess(
          _trendingBooks,
          trendingBooks: _trendingBooks,
          newReleases: _newReleases,
          noteworthyBooks: _noteworthyBooks,
          isMockData: _useMockData,
        ));
      } else {
        emit(HomeError("No books could be loaded"));
      }

    } on TimeoutException {
      debugPrint("Timeout in _loadDataSequentially");
      await _loadSimplifiedData();
    } catch (e) {
      debugPrint("Error in _loadDataSequentially: $e");
      await _loadSimplifiedData();
    }
  }

  Future<List<Items>> _getSimpleTrendingBooks() async {
    try {
      // Try NYT first
      final nytBooks = await _getBooksFromNYT(() => nytBooksRepo.getTrendingBooks());
      if (nytBooks.isNotEmpty) return nytBooks.take(10).toList();

      // Fallback to Google
      return await apiRepo.getTrendingBooks().timeout(Duration(seconds: 15));
    } catch (e) {
      debugPrint("Simple trending failed: $e");
      return [];
    }
  }

  Future<List<Items>> _getSimpleNewReleases() async {
    try {
      // Try NYT first
      final nytBooks = await _getBooksFromNYT(() => nytBooksRepo.getNewReleases());
      if (nytBooks.isNotEmpty) return nytBooks.take(8).toList();

      // Fallback to Google
      return await apiRepo.getNewReleases().timeout(Duration(seconds: 15));
    } catch (e) {
      debugPrint("Simple new releases failed: $e");
      return [];
    }
  }

  Future<List<Items>> _getSimpleRecommendedBooks() async {
    try {
      // Try NYT first
      final nytBooks = await _getBooksFromNYT(() => nytBooksRepo.getRecommendedBooks());
      if (nytBooks.isNotEmpty) return nytBooks.take(6).toList();

      // Fallback: mix of trending and diverse
      final diverse = await _getDiverseGenreBooks();
      return diverse.take(6).toList();
    } catch (e) {
      debugPrint("Simple recommended failed: $e");
      return [];
    }
  }
  Future<List<Items>> _getHybridTrendingBooks() async {
    final List<Items> allBooks = [];

    try {
      // Try NYT first (with longer timeout)
      final nytBooks = await _getBooksFromNYT(() => nytBooksRepo.getTrendingBooks());
      allBooks.addAll(nytBooks);

      // If NYT failed or returned empty, use Google with fallback
      if (allBooks.isEmpty) {
        try {
          final googleBooks = await apiRepo.getEnhancedTrendingBooks()
              .timeout(Duration(seconds: 15));
          allBooks.addAll(googleBooks);
        } catch (e) {
          debugPrint("Google trending also failed: $e");
          // Final fallback
          final fallbackBooks = await apiRepo.getTrendingBooks()
              .timeout(Duration(seconds: 10));
          allBooks.addAll(fallbackBooks);
        }
      }

    } catch (e) {
      debugPrint("Hybrid trending completely failed: $e");
      // Ultimate fallback
      final ultimateFallback = await apiRepo.getTrendingBooks()
          .timeout(Duration(seconds: 8));
      allBooks.addAll(ultimateFallback);
    }

    return _removeDuplicates(allBooks).take(10).toList();
  }

  Future<List<Items>> _getHybridNewReleases() async {
    final List<Items> allBooks = [];

    try {
      // Source 1: NYT new releases
      final nytBooks = await _getBooksFromNYT(nytBooksRepo.getNewReleases);
      allBooks.addAll(nytBooks);

      // Source 2: Google enhanced new releases
      final googleBooks = await apiRepo.getEnhancedNewReleases();
      allBooks.addAll(googleBooks);

      // Source 3: Recent books from various genres
      final recentFiction = await apiRepo.getBooksByGenre("fiction");
      final recentMystery = await apiRepo.getBooksByGenre("mystery");
      allBooks.addAll(recentFiction.take(2));
      allBooks.addAll(recentMystery.take(2));

    } catch (e) {
      debugPrint("Hybrid new releases error: $e");
    }

    // Filter for actual recent books and remove duplicates
    return _filterAndRemoveDuplicates(allBooks).take(8).toList();
  }

  Future<List<Items>> _getHybridRecommendedBooks() async {
    final List<Items> allBooks = [];

    try {
      // Source 1: NYT recommendations
      final nytBooks = await _getBooksFromNYT(nytBooksRepo.getRecommendedBooks);
      allBooks.addAll(nytBooks);

      // Source 2: High-rated books from Google
      final highRatedBooks = await _getHighRatedBooks();
      allBooks.addAll(highRatedBooks);

      // Source 3: Diverse genres from Google
      final diverseBooks = await _getDiverseGenreBooks();
      allBooks.addAll(diverseBooks);

    } catch (e) {
      debugPrint("Hybrid recommended error: $e");
    }

    return _removeDuplicates(allBooks).take(6).toList();
  }

  Future<List<Items>> _getHighRatedBooks() async {
    try {
      // Get books from multiple genres and filter for high ratings
      final List<Items> highRatedBooks = [];

      final genresToSearch = ["fiction", "mystery", "science fiction", "biography"];

      for (final genre in genresToSearch) {
        final books = await apiRepo.getBooksByGenre(genre);
        final highRated = books.where((book) =>
        (book.volumeInfo?.averageRating ?? 0) >= 4.0
        ).take(2).toList();

        highRatedBooks.addAll(highRated);
      }

      return highRatedBooks;
    } catch (e) {
      debugPrint("High rated books error: $e");
      return [];
    }
  }

  Future<List<Items>> _getDiverseGenreBooks() async {
    try {
      // Get books from diverse genres
      final List<Items> diverseBooks = [];

      const diverseGenres = [
        "history", "science", "travel", "cooking", "art"
      ];

      for (final genre in diverseGenres) {
        final books = await apiRepo.getBooksByGenre(genre);
        diverseBooks.addAll(books.take(1));
      }

      return diverseBooks;
    } catch (e) {
      debugPrint("Diverse genre books error: $e");
      return [];
    }
  }

  List<Items> _filterAndRemoveDuplicates(List<Items> books) {
    // Filter for recent books (last year)
    final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
    final recentBooks = books.where((book) {
      final dateStr = book.volumeInfo?.publishedDate;
      if (dateStr == null) return true; // Keep if no date

      try {
        final parsedDate = DateTime.parse(dateStr);
        return parsedDate.isAfter(oneYearAgo);
      } catch (_) {
        return true; // Keep if date parsing fails
      }
    }).toList();

    // Remove duplicates
    return _removeDuplicates(recentBooks);
  }

  List<Items> _removeDuplicates(List<Items> books) {
    final seenIds = <String>{};
    return books.where((book) {
      if (book.id != null && !seenIds.contains(book.id!)) {
        seenIds.add(book.id!);
        return true;
      }
      return false;
    }).toList();
  }

  Future<List<Items>> getRealBestsellers() async {
    try {
      debugPrint("Starting getRealBestsellers...");

      // First try ISBN search (most reliable) - but LIMITED
      final isbns = await nytBooksRepo.fetchAllBestsellerISBNs();
      debugPrint("Fetched ${isbns.length} ISBNs from NYT");

      if (isbns.isNotEmpty) {
        debugPrint("Trying ISBN search...");
        final booksByIsbn = await apiRepo.getBooksByISBNs(isbns);
        debugPrint("ISBN search found ${booksByIsbn.length} books");
        if (booksByIsbn.isNotEmpty) return booksByIsbn;
      }

      // Fallback to title search - also LIMITED
      debugPrint("Falling back to title search...");
      final titles = await nytBooksRepo.fetchAllBestsellerTitles();
      final limitedTitles = titles.take(3).toList(); // Reduce to 3 titles
      debugPrint("Searching for titles: $limitedTitles");

      final booksByTitle = await apiRepo.getBooksFromTitles(limitedTitles);
      debugPrint("Title search found ${booksByTitle.length} books");

      return booksByTitle.isNotEmpty
          ? booksByTitle
          : await _currentRepo.getTrendingBooks();
    } catch (e) {
      debugPrint("Error in getRealBestsellers: $e");
      return await _currentRepo.getTrendingBooks();
    }
  }

  Future<void> loadRealBestsellers() async {
    await _throttledApiCall(() async {
      emit(HomeLoading());
      try {
        final books = await getRealBestsellers();
        _trendingBooks = books;
        emit(HomeSuccess(
            books,
            trendingBooks: books,
            newReleases: _newReleases,
            noteworthyBooks: _noteworthyBooks,
            isMockData: _useMockData,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }

  Future<void> initializeData({int retryCount = 0}) async {
    if (retryCount > 2) {
      await _emergencyFallback(); // Use emergency fallback instead of switch
      return;
    }

    emit(HomeLoading());

    try {
      await _loadDataSequentially().timeout(Duration(seconds: 30));
    } on TimeoutException {
      debugPrint("Overall initialization timeout");
      if (retryCount < 2) {
        await initializeData(retryCount: retryCount + 1);
      } else {
        await _emergencyFallback();
      }
    } catch (e) {
      debugPrint("Initialize error: $e");
      await _emergencyFallback();
    }
  }

  // Future<void> initializeData({int retryCount = 0}) async {
  //   debugPrint("Initializing data...");
  //   emit(HomeLoading());
  //
  //   try {
  //     // Start with simple loading first
  //     _trendingBooks = await _currentRepo.getTrendingBooks().timeout(Duration(seconds: 15));
  //     debugPrint("Loaded ${_trendingBooks.length} trending books");
  //
  //     _newReleases = await _currentRepo.getNewReleases().timeout(Duration(seconds: 15));
  //     debugPrint("Loaded ${_newReleases.length} new releases");
  //
  //     _noteworthyBooks = _trendingBooks.take(5).toList();
  //
  //     emit(HomeSuccess(
  //       _trendingBooks,
  //       trendingBooks: _trendingBooks,
  //       newReleases: _newReleases,
  //       noteworthyBooks: _noteworthyBooks,
  //       isMockData: _useMockData,
  //     ));
  //
  //   } catch (e) {
  //     debugPrint("Simple initialization failed: $e");
  //     if (retryCount < 2) {
  //       await initializeData(retryCount: retryCount + 1);
  //     } else {
  //       await _emergencyFallback();
  //     }
  //   }
  // }

  Future<List<Items>> _getBooksFromNYT(Future<List<NYTBook>> Function() nytFunction) async {
    try {
      final nytBooks = await nytFunction().timeout(Duration(seconds: 15));

      if (nytBooks.isEmpty) return [];

      // Get ISBNs for searching
      final isbns = nytBooks
          .map((book) => book.primaryIsbn13 ?? book.primaryIsbn10)
          .where((isbn) => isbn != null && isbn.isNotEmpty)
          .cast<String>()
          .toList();

      if (isbns.isNotEmpty) {
        final booksByIsbn = await apiRepo.getBooksByISBNs(isbns);
        if (booksByIsbn.isNotEmpty) return booksByIsbn;
      }

      // Fallback to EXACT title search
      final titles = nytBooks
          .map((book) => book.title)
          .where((title) => title != null && title.isNotEmpty)
          .cast<String>()
          .toList();

      if (titles.isEmpty) return [];

      return await apiRepo.getBooksFromTitles(titles.take(3).toList());

    } on TimeoutException {
      debugPrint("Timeout in _getBooksFromNYT");
      return []; // Return empty instead of throwing
    } catch (e) {
      debugPrint("Error in _getBooksFromNYT: $e");
      return []; // Return empty instead of throwing
    }
  }

  // Future<void> _loadSimplifiedData() async {
  //   try {
  //     // Just load trending books as fallback
  //     _trendingBooks = await _currentRepo.getTrendingBooks()
  //         .timeout(Duration(seconds: 10));
  //
  //     emit(HomeSuccess(
  //       _trendingBooks,
  //       trendingBooks: _trendingBooks,
  //       newReleases: [],
  //       noteworthyBooks: [],
  //       isMockData: _useMockData,
  //     ));
  //   } catch (e) {
  //     emit(HomeError("Could not load any data"));
  //   }
  // }
  // Future<void> _loadDataSequentially() async {
  //   try {
  //     debugPrint("Starting sequential load...");
  //
  //     // Just load trending books first to test
  //     _trendingBooks = await _currentRepo.getTrendingBooks()
  //         .timeout(Duration(seconds: 15));
  //     debugPrint("Loaded ${_trendingBooks.length} trending books");
  //
  //     // Load new releases
  //     _newReleases = await _currentRepo.getNewReleases()
  //         .timeout(Duration(seconds: 15));
  //     debugPrint("Loaded ${_newReleases.length} new releases");
  //
  //     // Skip NYT for now to test basic functionality
  //     _noteworthyBooks = _trendingBooks.take(5).toList();
  //
  //     debugPrint("Emitting HomeSuccess...");
  //     emit(HomeSuccess(
  //       _trendingBooks,
  //       trendingBooks: _trendingBooks,
  //       newReleases: _newReleases,
  //       noteworthyBooks: _noteworthyBooks,
  //       isMockData: _useMockData,
  //     ));
  //     debugPrint("HomeSuccess emitted successfully");
  //
  //   } on TimeoutException {
  //     debugPrint("Timeout in _loadDataSequentially");
  //     emit(HomeError("Request timed out. Please try again."));
  //   } catch (e) {
  //     debugPrint("Error in _loadDataSequentially: $e");
  //     emit(HomeError("Failed to load data: ${e.toString()}"));
  //   }
  // }

  Future<void> _loadSimplifiedData() async {
    try {
      // Use Google Books as primary fallback since it's more reliable
      _trendingBooks = await apiRepo.getEnhancedTrendingBooks();
      _newReleases = await apiRepo.getEnhancedNewReleases();

      // For recommendations, use a mix of trending and diverse genres
      final diverseBooks = await _getDiverseGenreBooks();
      _noteworthyBooks = [..._trendingBooks.take(3), ...diverseBooks.take(3)];

      emit(HomeSuccess(
        _trendingBooks,
        trendingBooks: _trendingBooks,
        newReleases: _newReleases,
        noteworthyBooks: _noteworthyBooks,
        isMockData: _useMockData,
      ));

    } catch (e) {
      debugPrint("Simplified data also failed: $e");
      // Final fallback to mock data
      _trendingBooks = await mockRepo.getTrendingBooks();
      _newReleases = await mockRepo.getNewReleases();
      _noteworthyBooks = await mockRepo.getRecommendedBooks();

      emit(HomeSuccess(
        _trendingBooks,
        trendingBooks: _trendingBooks,
        newReleases: _newReleases,
        noteworthyBooks: _noteworthyBooks,
        isMockData: true, // Force mock data flag
      ));
    }
  }

  Future<void> _emergencyFallback() async {
    try {
      debugPrint("Using emergency fallback...");

      // Use mock data directly
      _trendingBooks = await mockRepo.getTrendingBooks();
      _newReleases = await mockRepo.getNewReleases();
      _noteworthyBooks = _trendingBooks.take(5).toList();

      emit(HomeSuccess(
        _trendingBooks,
        trendingBooks: _trendingBooks,
        newReleases: _newReleases,
        noteworthyBooks: _noteworthyBooks,
        isMockData: true,
      ));

    } catch (e) {
      debugPrint("Emergency fallback also failed: $e");
      emit(HomeError("Could not load any data. Please check your connection."));
    }
  }


  Future<List<Items>> _getRecommendedBooks() async {
    try {
      final recommendedBooks = await nytBooksRepo.getRecommendedBooks();

      // Get actual book data using ISBNs (most reliable)
      final isbns = recommendedBooks
          .map((book) => book.primaryIsbn13 ?? book.primaryIsbn10)
          .where((isbn) => isbn != null && isbn.isNotEmpty)
          .cast<String>()
          .toList();

      if (isbns.isNotEmpty) {
        final booksByIsbn = await apiRepo.getBooksByISBNs(isbns);
        if (booksByIsbn.isNotEmpty) return booksByIsbn;
      }

      // Fallback to title search
      final titles = recommendedBooks
          .map((book) => book.title)
          .where((title) => title != null && title.isNotEmpty)
          .cast<String>()
          .toList();

      return await apiRepo.getBooksFromTitles(titles.take(8).toList());

    } catch (e) {
      debugPrint("Error getting recommended books: $e");
      return _newReleases.take(5).toList(); // Fallback to new releases
    }
  }

  Future<List<Items>> _getNewReleasesFromNYT() async {
    try {
      final newReleaseBooks = await nytBooksRepo.getNewReleases();

      // Get actual book data using ISBNs (most reliable)
      final isbns = newReleaseBooks
          .map((book) => book.primaryIsbn13 ?? book.primaryIsbn10)
          .where((isbn) => isbn != null && isbn.isNotEmpty)
          .cast<String>()
          .toList();

      if (isbns.isNotEmpty) {
        final booksByIsbn = await apiRepo.getBooksByISBNs(isbns);
        if (booksByIsbn.isNotEmpty) return booksByIsbn;
      }

      // Fallback to title search if ISBN search fails
      final titles = newReleaseBooks
          .map((book) => book.title)
          .where((title) => title != null && title.isNotEmpty)
          .cast<String>()
          .toList();

      return await apiRepo.getBooksFromTitles(titles.take(3).toList());

    } catch (e) {
      debugPrint("Error getting NYT new releases: $e");
      // Fallback to Google Books new releases
      return await _currentRepo.getNewReleases();
    }
  }

  Future<void> getTrendingBooks() async {
    await loadRealBestsellers();
  }

  Future<void> getBooksByGenre(String genre, int index) async {
    await _throttledApiCall(() async {
      emit(HomeLoading());
      try {
        // Let the repo handle caching - remove the _cachedApiCall wrapper
        final books = await _currentRepo.getBooksByGenre(genre);

        currentGenreIndex = index;
        showGenreView = true;
        emit(HomeSuccess(
          books,
          trendingBooks: _trendingBooks,
          newReleases: _newReleases,
          noteworthyBooks: _noteworthyBooks,
          isMockData: _useMockData,
        ));
      } catch (e) {
        if (_shouldUseMockData(e)) {
          await _switchToMockData();
          await getBooksByGenre(genre, index);
        } else {
          emit(HomeError(e.toString()));
        }
      }
    });
  }

  Future<void> searchBooks(String query) async {
    _searchTimer?.cancel();

    if (query.isEmpty) {
      emit(HomeSuccess(
          _trendingBooks,
          trendingBooks: _trendingBooks,
          newReleases: _newReleases,
          isMockData: _useMockData,
          noteworthyBooks: _noteworthyBooks
      ));
      return;
    }

    _searchTimer = Timer(Duration(milliseconds: 500), () async {
      await _throttledApiCall(() async {
        emit(HomeLoading());
        try {
          // Let the repo handle caching
          final books = await _currentRepo.searchBooks(query);

          emit(HomeSuccess(
            books,
            trendingBooks: _trendingBooks,
            newReleases: _newReleases,
            noteworthyBooks: _noteworthyBooks,
            isMockData: _useMockData,
          ));
        } catch (e) {
          if (_shouldUseMockData(e)) {
            await _switchToMockData();
            await searchBooks(query);
          } else {
            emit(HomeError(e.toString()));
          }
        }
      });
    });
  }

  Future<void> getNewReleases() async {
    await _throttledApiCall(() async {
      emit(HomeLoading());
      try {
        // Use NYT new releases instead of Google Books
        final books = await _cachedApiCall(
          'new_releases',
              () => _getNewReleasesFromNYT(),
        );
        _newReleases = books;
        emit(HomeSuccess(
          books,
          trendingBooks: _trendingBooks,
          newReleases: books,
          noteworthyBooks: _noteworthyBooks,
          isMockData: _useMockData,
        ));
      } catch (e) {
        if (_shouldUseMockData(e)) {
          await _switchToMockData();
          await getNewReleases();
        } else {
          emit(HomeError(e.toString()));
        }
      }
    });
  }

  // Helper methods
  Future<void> _throttledApiCall(Future<void> Function() apiCall) async {
    if (_isLoading) return;

    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);
    if (timeSinceLastCall < _minCallInterval) {
      await Future.delayed(_minCallInterval - timeSinceLastCall);
    }

    _isLoading = true;
    _lastApiCall = DateTime.now();

    try {
      await apiCall();
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Items>> _cachedApiCall(
      String cacheKey,
      Future<List<Items>> Function() apiCall
      ) async {
    try {
      debugPrint("Making API call through repo for: $cacheKey");

      // Just call the repo directly - it handles caching internally
      final result = await apiCall().timeout(Duration(seconds: 15));

      debugPrint("Fetched ${result.length} items for: $cacheKey");
      return result;
    } on TimeoutException {
      debugPrint("Timeout in API call for: $cacheKey");
      return [];
    } catch (e) {
      debugPrint("API failed for $cacheKey: $e");
      return [];
    }
  }

  Future<void> _switchToMockData() async {
    if (!_useMockData) {
      _useMockData = true;
      debugPrint('API quota exceeded. Switching to mock data...');
      _trendingBooks = [];
      _newReleases = [];
      _noteworthyBooks = [];
    }
  }

  bool _shouldUseMockData(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          return statusCode == 429 || statusCode == 403;
        default:
          return false;
      }
    }

    final errorString = e.toString().toLowerCase();
    return errorString.contains('429') ||
        errorString.contains('quota') ||
        errorString.contains('exceeded') ||
        errorString.contains('limit') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  void showAllBooks() {
    showGenreView = false;
    getTrendingBooks();
  }

  void toggleMockData(bool useMock) {
    _useMockData = useMock;
    debugPrint(_useMockData ? 'Using mock data' : 'Using real API data');
    initializeData();
  }

  @override
  void onChange(Change<HomeState> change) {
    super.onChange(change);
    debugPrint('STATE CHANGE: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');

    if (change.nextState is HomeSuccess) {
      final successState = change.nextState as HomeSuccess;
      debugPrint('SUCCESS: ${successState.books.length} books, '
          '${successState.trendingBooks?.length} trending, '
          '${successState.newReleases?.length} new releases, '
          '${successState.noteworthyBooks?.length} noteworthy');
    } else if (change.nextState is HomeError) {
      final errorState = change.nextState as HomeError;
      debugPrint('ERROR: ${errorState.message}');
    }
  }
}