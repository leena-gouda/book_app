import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../home/data/models/book_model.dart';
import '../../data/models/user_book_model.dart';
import '../../data/repos/library_repo.dart';

part 'my_library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository repository;

  LibraryCubit(this.repository) : super(LibraryInitial());

  Future<void> loadBooks(String status) async {
    emit(LibraryLoading());
    try {
      final normalized = normalizeStatus(status);
      final books = normalized == 'All'
          ? await repository.fetchAllBooks()
          : await repository.fetchBooksByStatus(normalized);
      print("🔍 Requested status: '$status'");
      print("🔍 Normalized status: '$normalized'");

      for (var book in books) {
        print("📖 ${book.bookId} - ${book.status}");
      }

      emit(LibraryLoaded(books: books));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

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

      await loadBooks(status); // Refresh view
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> updateBookProgress(String bookId, double progress) async {
    try {
      await repository.updateProgress(
        userId: Supabase.instance.client.auth.currentUser!.id,
        bookId: bookId,
        progress: progress,
      );
      if (state is LibraryLoaded) {
        final updatedBooks = (state as LibraryLoaded).books.map((book) {
          if (book.bookDetails.id == bookId) {
            return book.copyWith(progress: progress,category: "none");
          }
          return book;
        }).toList();

        emit(LibraryLoaded(books: updatedBooks));
      }



      // Optionally reload books or emit a progress update state
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

      // Optionally reload the current filter view
      await loadBooks('Finished');
    } catch (e) {
      emit(LibraryError("Failed to mark as finished: ${e.toString()}"));
    }
  }
  Future<void> moveBookToCategory(String bookId, String category) async {
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      final updatedBook = await repository.updateBookCategory(
        userId: userId,
        bookId: bookId,
        category: category,
      );

      if (updatedBook != null) {
        final updatedBooks = currentState.books.map((book) {
          return book.bookId == bookId ? updatedBook : book;
        }).toList();

        emit(currentState.copyWith(books: updatedBooks));
      }
    }
  }



}

