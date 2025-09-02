part of 'my_library_cubit.dart';

abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<UserBook> books;
  final List<Book> completeLibrary;

  LibraryLoaded( {required this.books,this.completeLibrary = const []});

  LibraryLoaded copyWith({List<UserBook>? books}) {
    return LibraryLoaded(
      books: books ?? this.books,
    );
  }
}


class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);
}
