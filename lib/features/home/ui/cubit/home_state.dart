part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeSuccess extends HomeState {
  final List<Items> books;
  final List<Items> trendingBooks;
  final List<Items> newReleases;
  final List<Items> noteworthyBooks;
  final bool isMockData;

  HomeSuccess(
      this.books, {
        required this.trendingBooks,
        required this.newReleases,
        required this.noteworthyBooks,
        required this.isMockData,
      });
}

final class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}