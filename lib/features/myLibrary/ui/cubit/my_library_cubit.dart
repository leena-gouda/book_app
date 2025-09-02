import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../home/data/models/book_model.dart';
import '../../data/models/user_book_model.dart';
import '../../data/repos/library_repo.dart';

part 'my_library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository repository;
  List<UserBook> _allBooks = [];

  LibraryCubit(this.repository) : super(LibraryInitial());

  Future<void> loadBooks(String status) async {
    emit(LibraryLoading());
    try {
      if (_allBooks.isEmpty) {
        _allBooks = await repository.fetchAllBooks();
      }
      List<UserBook> filteredBooks = _allBooks;

      if (status == 'Lists') {
        emit(LibraryLoaded(books: [])); // Empty books list for Lists tab
        return;
      }

      if (status != 'All') {
        final normalized = normalizeStatus(status);
        filteredBooks = _allBooks.where((book) => book.status == normalized).toList();
      }
      print("🔍 Requested status: '$status'");
      print("📚 Showing ${filteredBooks.length} books");
      for (var book in filteredBooks) {
        print("📖 ${book.bookId} - ${book.status} - Progress: ${book.progress}%");
      }

      emit(LibraryLoaded(books: filteredBooks));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  List<UserBook> getAllBooks() => _allBooks;


  String normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'to read':
      case 'to_read':
        return 'to_read';
      case 'reading':
        return 'reading';
      case 'finished':
        return 'finished';
      case 'all':
        return 'All';
      case 'lists':
        return 'Lists';
      default:
        return status.trim().toLowerCase();
    }
  }


  Future<void> setBookStatus(String bookId, String status, {double progress = 0, required Items book}) async {
    emit(LibraryLoading());
    try {
      await repository.saveBookStatus(
        userId: Supabase.instance.client.auth.currentUser!.id,
        bookId: bookId,
        status: status,
        progress: progress, 
        book: book,
      );
      print("📤 Supabase query with status: '$status'");

      print("📤 Sending progress: $progress for book: $bookId");

      _allBooks = await repository.fetchAllBooks(); // Refresh complete library
      await loadBooks(status);

    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> markAsFinished(String bookId, {required Items book}) async {
    emit(LibraryLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      await repository.saveBookStatus(
        userId: userId,
        bookId: bookId,
        status: 'finished',
        progress: 100,
        book: book,
      );

      // Refresh the local cache and reload
      _allBooks = await repository.fetchAllBooks(); // Refresh complete library
      await loadBooks('Finished'); // Switch to Finished tab
    } catch (e) {
      emit(LibraryError("Failed to mark as finished: ${e.toString()}"));
    }
  }

  Future<void> updateBookProgress(String bookId, double newProgress) async {
    try {
      // Determine the appropriate status based on progress
      String newStatus;
      if (newProgress == 0) {
        newStatus = 'to_read';
      } else if (newProgress == 100) {
        newStatus = 'finished';
      } else {
        newStatus = 'reading';
      }

      // Update both progress and status in the repository
      await repository.updateProgressAndStatus(
        userId: Supabase.instance.client.auth.currentUser!.id,
        bookId: bookId,
        progress: newProgress,
        status: newStatus,
      );

      final index = _allBooks.indexWhere((book) => book.bookId == bookId);
      if (index != -1) {
        _allBooks[index] = _allBooks[index].copyWith(
          progress: newProgress,
          status: newStatus,
        );
      }

      // Update local state
      if (state is LibraryLoaded) {
        final updatedBooks = (state as LibraryLoaded).books.map((book) {
          if (book.bookId == bookId) {
            return book.copyWith(progress: newProgress, status: newStatus);
          }
          return book;
        }).toList();

        emit(LibraryLoaded(books: updatedBooks));
      }
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> refreshAllBooks() async {
    _allBooks = await repository.fetchAllBooks();

    // Reload current view if we're in a loaded state
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      // You might want to preserve the current filter logic here
      // For simplicity, we'll just reload with the current books
      emit(LibraryLoaded(books: currentState.books));
    }
  }

}

