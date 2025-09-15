part of 'dashboard_cubit.dart';

abstract class DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSuccess extends DashboardState {
  final List<UserBook> books;
  final int totalBooks;
  final int finishedBooks;
  final int goal;
  final int currentlyReading;
  final int totalPagesRead;
  final int currentStreak;
  final int longestStreak;
  final List<MonthlyReadingData> monthlyReadingData;
  final String timeFilter;

  DashboardSuccess({
    required this.books,
    required this.totalBooks,
    required this.finishedBooks,
    required this.currentlyReading,
    required this.goal,
    required this.totalPagesRead,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyReadingData,
    required this.timeFilter,


  }) ;

  DashboardSuccess copyWith({
    List<UserBook>? books,
    int? totalBooks,
    int? finishedBooks,
    int? goal,
    int? currentlyReading,
    int? totalPagesRead,
    int? currentStreak,
    int? longestStreak,
    List<MonthlyReadingData>? monthlyReadingData,
    String? timeFilter,
  }) {
    return DashboardSuccess(
      books: books ?? this.books,
      totalBooks: totalBooks ?? this.totalBooks,
      finishedBooks: finishedBooks ?? this.finishedBooks,
      currentlyReading: currentlyReading ?? this.currentlyReading,
      goal: goal ?? this.goal,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      monthlyReadingData: monthlyReadingData ?? this.monthlyReadingData,
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }

}



class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
