// features/myLibrary/ui/cubit/list_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:book_app/features/home/data/models/book_model.dart';

import '../../data/models/custom_lists.dart';
import '../../data/repos/list_repo.dart';

part 'list_state.dart';

class ListCubit extends Cubit<ListState> {
  final ListRepository listRepository;

  ListCubit( this.listRepository) : super(ListInitial());

  // Load all lists for the current user
  Future<void> loadLists() async {
    emit(ListLoading());
    try {
      final lists = await listRepository.getCustomLists();
      emit(ListLoaded(lists: lists));
    } catch (e) {
      emit(ListError(message: e.toString()));
    }
  }

  // Create a new list
  Future<void> createList(String name) async {
    try {
      final newList = await listRepository.createList(name);

      // Update state with the new list
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = [newList, ...currentState.lists];
        emit(ListLoaded(lists: updatedLists));
      }
    } catch (e) {
      emit(ListError(message: e.toString()));
      // Re-emit the loaded state after showing error
      if (state is ListLoaded) {
        emit(state);
      }
    }
  }

  // Add a book to a list
  Future<void> addBookToList(int listId, String bookId, Items book) async {
    try {
      await listRepository.addBookToList(listId, bookId, book);

      // Update state to reflect the change
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == listId) {
            return CustomList(
              id: list.id,
              name: list.name,
              userId: list.userId,
              createdAt: list.createdAt,
              bookCount: list.bookCount + 1,
            );
          }
          return list;
        }).toList();

        emit(ListLoaded(lists: updatedLists));
      }
    } catch (e) {
      emit(ListError(message: e.toString()));
      // Re-emit the loaded state after showing error
      if (state is ListLoaded) {
        emit(state);
      }
    }
  }

  // Delete a list
  Future<void> deleteList(int listId) async {
    try {
      await listRepository.deleteList(listId);

      // Update state to remove the deleted list
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.where((list) => list.id != listId).toList();
        emit(ListLoaded(lists: updatedLists));
      }
    } catch (e) {
      emit(ListError(message: e.toString()));
      // Re-emit the loaded state after showing error
      if (state is ListLoaded) {
        emit(state);
      }
    }
  }

  // Update list name
  Future<void> updateListName(int listId, String newName) async {
    try {
      final updatedList = await listRepository.updateListName(listId, newName);

      // Update state with the updated list
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == listId) {
            return updatedList;
          }
          return list;
        }).toList();

        emit(ListLoaded(lists: updatedLists));
      }
    } catch (e) {
      emit(ListError(message: e.toString()));
      // Re-emit the loaded state after showing error
      if (state is ListLoaded) {
        emit(state);
      }
    }
  }

  Future<void> removeBookFromList(int listId, String bookId) async {
    try {
      await listRepository.removeBookFromList(listId, bookId);

      // Update state to reflect the change
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == listId) {
            return CustomList(
              id: list.id,
              name: list.name,
              userId: list.userId,
              createdAt: list.createdAt,
              bookCount: list.bookCount - 1,
            );
          }
          return list;
        }).toList();

        emit(ListLoaded(lists: updatedLists));
      }
    } catch (e) {
      emit(ListError(message: e.toString()));
      // Re-emit the loaded state after showing error
      if (state is ListLoaded) {
        emit(state);
      }
    }
  }
}