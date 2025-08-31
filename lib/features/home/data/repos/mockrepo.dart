import 'package:book_app/features/home/data/repos/book_api_repo.dart';

import '../models/book_model.dart';

class MockBooksRepo implements BooksApiRepo {
  final List<Items> _allMockBooks = _createAllMockBooks();

  @override
  Future<List<Items>> getTrendingBooks() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _allMockBooks.take(10).toList();
  }

  @override
  Future<List<Items>> getNewReleases() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _allMockBooks.take(8).toList();
  }

  @override
  Future<List<Items>> getBooksByGenre(String genre) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _allMockBooks
        .where((item) => item.volumeInfo?.categories?.any(
            (category) => category.toLowerCase().contains(genre.toLowerCase())) ?? false)
        .take(6)
        .toList();
  }

  @override
  Future<List<Items>> searchBooks(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lowercaseQuery = query.toLowerCase();
    return _allMockBooks
        .where((item) =>
    item.volumeInfo?.title?.toLowerCase().contains(lowercaseQuery) ??
        false)
        .take(4)
        .toList();
  }

  static List<Items> _createAllMockBooks() {
    final genres = [
      "Fiction", "Fantasy", "Romance", "Science Fiction", "Mystery",
      "Thriller", "Nonfiction", "Biography", "History", "Science"
    ];

    return List.generate(50, (index) {
      final bookGenres = [genres[index % genres.length]];
      if (index % 3 == 0 && bookGenres.length < 3) {
        bookGenres.add(genres[(index + 2) % genres.length]);
      }

      return Items(
        id: 'mock_book_$index',
        volumeInfo: VolumeInfo(
          title: 'Mock Book ${index + 1}: ${bookGenres.join(" & ")}',
          authors: ['Author ${(index % 5) + 1}', if (index % 2 == 0) 'Co-Author ${(index % 3) + 1}'],
          description: 'This is a detailed description for Book ${index + 1} in the ${bookGenres.join("/")} genre. '
              'A captivating story that will keep you engaged from start to finish.',
          categories: bookGenres,
          publishedDate: '${2020 + (index % 4)}-${(index % 12) + 1}-${(index % 28) + 1}',
          imageLinks: ImageLinks(
            thumbnail: 'https://placehold.co/300x450/0077B6/FFFFFF/png?text=Book+${index + 1}',
            smallThumbnail: 'https://placehold.co/128x192/0077B6/FFFFFF/png?text=Book+${index + 1}',
          ),
          averageRating: 3.5 + (index % 7) * 0.5,
          ratingsCount: 50 + index * 10,
        ),
      );
    });
  }

  @override
  void clearCache() {
    // TODO: implement clearCache
  }

  @override
  Future<List<Items>> fetchItemIds() {
    // TODO: implement fetchItemIds
    throw UnimplementedError();
  }

  @override
  Future<List<Items>> getBooksFromTitles(List<String> titles) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final lowercaseTitles = titles.map((t) => t.toLowerCase()).toList();

    return _allMockBooks.where((item) {
      final title = item.volumeInfo?.title?.toLowerCase() ?? '';
      return lowercaseTitles.any((query) => title.contains(query));
    }).toList();
  }

  @override
  Future<List<Items>> getBooksByISBNs(List<String> isbns) {
    // TODO: implement getBooksByISBNs
    throw UnimplementedError();
  }

  @override
  Future<List<Items>> getBooksFromTitlesIndividual(List<String> titles) {
    // TODO: implement getBooksFromTitlesIndividual
    throw UnimplementedError();
  }

  @override
  Future<List<Items>> getEnhancedNewReleases() {
    // TODO: implement getEnhancedNewReleases
    throw UnimplementedError();
  }

  @override
  Future<List<Items>> getEnhancedTrendingBooks() {
    // TODO: implement getEnhancedTrendingBooks
    throw UnimplementedError();
  }

  @override
  Future<List<Items>> getMixedBooks({String? genre, int limit = 10}) {
    // TODO: implement getMixedBooks
    throw UnimplementedError();
  }

  Future<List<Items>> getRecommendedBooks() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Return different books than trending/new releases for variety
    return _allMockBooks
        .where((book) => book.id?.contains('3') ?? false) // Different subset
        .take(6)
        .toList();
  }
}