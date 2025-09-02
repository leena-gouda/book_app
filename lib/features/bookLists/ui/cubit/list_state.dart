// features/myLibrary/ui/cubit/list_state.dart
part of 'list_cubit.dart';

abstract class ListState {
  const ListState();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListState && runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

class ListInitial extends ListState {
  const ListInitial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ListInitial;
  }

  @override
  int get hashCode => 0;
}

class ListLoading extends ListState {
  const ListLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ListLoading;
  }

  @override
  int get hashCode => 1;
}

class ListLoaded extends ListState {
  final List<CustomList> lists;

  const ListLoaded({required this.lists});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListLoaded &&
        runtimeType == other.runtimeType &&
        _listEquals(other.lists, lists);
  }

  @override
  int get hashCode => lists.hashCode;
}

class ListError extends ListState {
  final String message;

  const ListError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListError &&
        runtimeType == other.runtimeType &&
        message == other.message;
  }

  @override
  int get hashCode => message.hashCode;
}

// Helper function to compare lists for equality
bool _listEquals<T>(List<T>? list1, List<T>? list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  if (list1.length != list2.length) return false;

  for (var i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}