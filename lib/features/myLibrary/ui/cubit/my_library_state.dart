part of 'my_library_cubit.dart';

abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<UserBook> books;

  LibraryLoaded({required this.books});

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
