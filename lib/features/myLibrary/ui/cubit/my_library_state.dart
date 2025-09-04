part of 'my_library_cubit.dart';

abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<UserBook> books;
  final List<Book> completeLibrary;
  final String currentFilter;

  LibraryLoaded( {required this.books,required this.currentFilter,this.completeLibrary = const []});

  LibraryLoaded copyWith({List<UserBook>? books, String? currentFilter, List<Book>? completeLibrary}) {
    return LibraryLoaded(
      books: books ?? this.books,
      currentFilter: currentFilter ?? this.currentFilter,
      completeLibrary: completeLibrary ?? this.completeLibrary
    );
  }
}


class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}
