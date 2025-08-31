import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../../core/constants/endpoint_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/nyt_model.dart';

class NYTBooksRepo {
  final DioClient _dioClient;
  final String _nytApiKey = 'Uv3xbPsWbD6W7KqUb00W72o0johDpPcX';

  NYTResponse? _cachedNytData;
  DateTime? _cacheTime;
  final Duration _cacheDuration = Duration(minutes: 30);

  NYTBooksRepo(this._dioClient);

  Future<NYTResponse> fetchBestsellersData() async {
    // Check cache first
    if (_cachedNytData != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      debugPrint("Using cached NYT data");
      return _cachedNytData!;
    }

    try {
      final response = await _dioClient.get(
        EndpointConstants.nyt,
        queryParameters: {'api-key': _nytApiKey},
      ).timeout(Duration(seconds: 15));

      _cachedNytData = NYTResponse.fromJson(response.data);
      _cacheTime = DateTime.now();

      return _cachedNytData!;
    } catch (e) {
      debugPrint("NYT API error: $e");
      throw Exception('Failed to fetch NYT bestsellers');
    }
  }

  // GET TRENDING BOOKS - Books moving up the list quickly
  Future<List<NYTBook>> getTrendingBooks() async {
    try {
      final nytData = await fetchBestsellersData().timeout(Duration(seconds: 10));
      final trendingBooks = <NYTBook>[];

      for (final list in nytData.results?.lists ?? []) {
        // Books that improved their rank significantly
        final risingBooks = list.books.where((book) =>
        book.rankLastWeek != null &&
            book.rank != null &&
            book.rank! < book.rankLastWeek! && // Moving up
            (book.rankLastWeek! - book.rank!) >= 5 // Jumped at least 5 spots
        ).toList();

        trendingBooks.addAll(risingBooks);
      }

      // Sort by biggest rank improvement
      trendingBooks.sort((a, b) {
        final aImprovement = (a.rankLastWeek ?? 99) - (a.rank ?? 99);
        final bImprovement = (b.rankLastWeek ?? 99) - (b.rank ?? 99);
        return bImprovement.compareTo(aImprovement); // Descending order
      });

      return _removeDuplicates(trendingBooks).take(15).toList();

    } on TimeoutException {
      debugPrint("NYT trending books timeout");
      return _getFallbackTrendingBooks();
    } catch (e) {
      debugPrint("Error getting trending books: $e");
      return _getFallbackTrendingBooks();
    }
  }

  // GET NEW RELEASES - Books that recently entered the bestseller list
  Future<List<NYTBook>> getNewReleases() async {
    try {
      final nytData = await fetchBestsellersData().timeout(Duration(seconds: 10));
      final newReleases = <NYTBook>[];

      for (final list in nytData.results?.lists ?? []) {
        // Strategy 1: Books that are brand new to the list (1-2 weeks)
        final brandNewBooks = list.books.where((book) =>
        book.weeksOnList != null &&
            book.weeksOnList! <= 2 &&
            book.rank != null &&
            book.rank! <= 15 // Only consider books that debuted well
        ).toList();

        // Strategy 2: Books that made significant jumps onto the list
        final bigJumpBooks = list.books.where((book) =>
        book.rankLastWeek == null && // Wasn't on list last week at all
            book.rank != null &&
            book.rank! <= 20 // Debuted in top 20
        ).toList();

        // Strategy 3: Books that recently entered top 10
        final top10Newbies = list.books.where((book) =>
        book.weeksOnList != null &&
            book.weeksOnList! <= 4 &&
            book.rank != null &&
            book.rank! <= 10
        ).toList();

        newReleases.addAll(brandNewBooks);
        newReleases.addAll(bigJumpBooks);
        newReleases.addAll(top10Newbies);
      }

      // Remove duplicates and prioritize by how "new" they are
      final uniqueNewReleases = _removeDuplicates(newReleases);

      // Sort by weeks on list (lowest first) then by rank (lowest first)
      uniqueNewReleases.sort((a, b) {
        final weeksCompare = (a.weeksOnList ?? 99).compareTo(b.weeksOnList ?? 99);
        if (weeksCompare != 0) return weeksCompare;
        return (a.rank ?? 99).compareTo(b.rank ?? 99);
      });

      return uniqueNewReleases.take(20).toList();

    } on TimeoutException {
      debugPrint("NYT new releases timeout");
      return _getFallbackNewReleases();
    } catch (e) {
      debugPrint("Error getting new releases from NYT: $e");
      return _getFallbackNewReleases();
    }
  }

  // GET RECOMMENDED BOOKS - Mix of current bestsellers and rising books
  Future<List<NYTBook>> getRecommendedBooks() async {
    try {
      final nytData = await fetchBestsellersData().timeout(Duration(seconds: 10));
      final recommendedBooks = <NYTBook>[];

      // Strategy: Mix of current bestsellers and rising books
      for (final list in nytData.results?.lists ?? []) {
        // Top 2 from each major list
        final topBooks = list.books.take(2).toList();
        recommendedBooks.addAll(topBooks);

        // Add books that are moving up the list (rising stars)
        final risingBooks = list.books.where((book) =>
        book.rankLastWeek != null &&
            book.rank != null &&
            book.rank! < book.rankLastWeek! // Moving up in rank
        ).take(1).toList();

        recommendedBooks.addAll(risingBooks);
      }

      // Remove duplicates and limit to 15 books
      final uniqueBooks = _removeDuplicates(recommendedBooks);
      return uniqueBooks.take(15).toList();

    } on TimeoutException {
      debugPrint("NYT recommended books timeout");
      return _getFallbackRecommendedBooks();
    } catch (e) {
      debugPrint("Error getting recommended books: $e");
      return _getFallbackRecommendedBooks();
    }
  }

  // Add this missing fallback method
  List<NYTBook> _getFallbackRecommendedBooks() {
    return [
      NYTBook(
        title: "The Midnight Library",
        author: "Matt Haig",
        primaryIsbn13: "9780525559474",
        weeksOnList: 3,
        rank: 6,
        description: "A novel about infinite possibilities...",
        publisher: "Viking",
        // ... other properties
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "0525559477",
        sundayReviewLink: "",
        updatedDate: DateTime.now(),
        isbns: [],
        buyLinks: [],
        rankLastWeek: 5,
      ),
      NYTBook(
        title: "Where the Crawdads Sing",
        author: "Delia Owens",
        primaryIsbn13: "9780735219090",
        weeksOnList: 8,
        rank: 5,
        description: "A coming-of-age story set in North Carolina...",
        publisher: "G.P. Putnam's Sons",
        // ... other properties
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "0735219095",
        rankLastWeek: 6,
        sundayReviewLink: "",
        updatedDate: DateTime.now(),
        isbns: [],
        buyLinks: [],
      ),
    ];
  }

  // ... keep your existing helper methods below ...
  List<NYTBook> _removeDuplicates(List<NYTBook> books) {
    final seenIsbns = <String>{};
    return books.where((book) {
      final isbn = book.primaryIsbn13 ?? book.primaryIsbn10;
      if (isbn != null && !seenIsbns.contains(isbn)) {
        seenIsbns.add(isbn);
        return true;
      }
      return false;
    }).toList();
  }

  // ... keep your existing fetchAllBestsellerBooks, fetchAllBestsellerTitles, etc.
  Future<List<NYTBook>> fetchAllBestsellerBooks() async {
    try {
      final nytData = await fetchBestsellersData();
      final allBooks = <NYTBook>[];

      for (final list in nytData.results?.lists ?? []) {
        allBooks.addAll(list.books);
      }

      return allBooks;
    } catch (e) {
      debugPrint("Error fetching books: $e");
      return _getFallbackBooks();
    }
  }

  Future<List<String>> fetchAllBestsellerTitles() async {
    final books = await fetchAllBestsellerBooks();
    return books.map((book) => book.title ?? 'Unknown Title').toList();
  }

  Future<List<String>> fetchAllBestsellerISBNs() async {
    final books = await fetchAllBestsellerBooks();

    // Use a Set to remove duplicates
    final isbnSet = <String>{};

    for (final book in books) {
      if (book.primaryIsbn13?.isNotEmpty ?? false) {
        isbnSet.add(book.primaryIsbn13!);
      }
      if (book.primaryIsbn10?.isNotEmpty ?? false) {
        isbnSet.add(book.primaryIsbn10!);
      }
    }

    return isbnSet.take(15).toList(); // LIMIT to 15 unique ISBNs
  }

  List<NYTBook> _getFallbackBooks() {
    return [
      NYTBook(
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        author: "Suzanne Collins",
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        description: "The Hunger Games trilogy...",
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "0439023483",
        primaryIsbn13: "9780439023481",
        publisher: "Scholastic Press",
        rank: 1,
        rankLastWeek: 0,
        sundayReviewLink: "",
        title: "The Hunger Games",
        updatedDate: DateTime.now(),
        weeksOnList: 52,
        isbns: [],
        buyLinks: [],
      ),
    ];
  }

  List<NYTBook> _getFallbackNewReleases() {
    return [
      NYTBook(
        title: "The Thursday Murder Club",
        author: "Richard Osman",
        primaryIsbn13: "9781984880987",
        weeksOnList: 1,
        rank: 3,
        rankLastWeek: null,
        description: "A group of retirees investigate murders...",
        publisher: "Penguin",
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "1984880985",
        sundayReviewLink: "",
        updatedDate: DateTime.now(),
        isbns: [],
        buyLinks: [],
      ),
    ];
  }

  List<NYTBook> _getFallbackTrendingBooks() {
    return [
      NYTBook(
        title: "Project Hail Mary",
        author: "Andy Weir",
        primaryIsbn13: "9780593135204",
        weeksOnList: 2,
        rank: 8,
        rankLastWeek: 15,
        description: "An astronaut saves humanity from disaster...",
        publisher: "Ballantine",
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "0593135202",
        sundayReviewLink: "",
        updatedDate: DateTime.now(),
        isbns: [],
        buyLinks: [],
      ),
    ];
  }

  // ... keep your existing getRecentBestsellers method if you need it ...
  Future<List<NYTBook>> getRecentBestsellers() async {
    try {
      final nytData = await fetchBestsellersData().timeout(Duration(seconds: 10));
      final recentBestsellers = <NYTBook>[];

      for (final list in nytData.results?.lists ?? []) {
        // Books that have been consistently popular (3-12 weeks)
        final consistentBestsellers = list.books.where((book) =>
        book.weeksOnList != null &&
            book.weeksOnList! >= 3 &&
            book.weeksOnList! <= 12 &&
            book.rank != null &&
            book.rank! <= 15
        ).toList();

        recentBestsellers.addAll(consistentBestsellers);
      }

      return _removeDuplicates(recentBestsellers).take(15).toList();

    } on TimeoutException {
      debugPrint("NYT recent bestsellers timeout");
      return _getFallbackRecentBestsellers();
    } catch (e) {
      debugPrint("Error getting recent bestsellers: $e");
      return _getFallbackRecentBestsellers();
    }
  }

  List<NYTBook> _getFallbackRecentBestsellers() {
    return [
      NYTBook(
        title: "Where the Crawdads Sing",
        author: "Delia Owens",
        primaryIsbn13: "9780735219090",
        weeksOnList: 8,
        rank: 5,
        description: "A coming-of-age story set in North Carolina...",
        publisher: "G.P. Putnam's Sons",
        ageGroup: "",
        amazonProductUrl: "",
        articleChapterLink: "",
        asterisk: 0,
        bookImage: "",
        bookImageHeight: 0,
        bookImageWidth: 0,
        bookReviewLink: "",
        bookUri: "",
        contributor: "",
        contributorNote: "",
        createdDate: DateTime.now(),
        dagger: 0,
        firstChapterLink: "",
        price: "0",
        primaryIsbn10: "0735219095",
        rankLastWeek: 6,
        sundayReviewLink: "",
        updatedDate: DateTime.now(),
        isbns: [],
        buyLinks: [],
      ),
    ];
  }
}