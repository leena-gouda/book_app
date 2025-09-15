import 'dart:math';

import 'package:book_app/features/dashboard/data/repo/dashboard_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../myLibrary/data/models/user_book_model.dart';
import '../../data/models/monthly_reading_model.dart';
import '../../data/models/reading_goal_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepo repo;

  DashboardCubit(this.repo) : super(DashboardLoading());

  Future<void> loadUserBooks(String userId) async {
    try {
      emit(DashboardLoading());

      final books = await repo.getUserBooks(userId);
      final currentYear = DateTime.now().year;

      final finishedBooks = books.where((b) =>
      b.status == 'finished' &&
          b.updatedDate != null &&
          b.updatedDate!.year == currentYear).length;

      final currentlyReading = books.where(
        (b) => b.status == 'reading',
      ).length;

      final readingGoal =
          await repo.getReadingGoal(userId, currentYear) ??
              ReadingGoal(userId: userId, year: currentYear, goal: 12); // default


      final totalPagesRead = books.fold<double>(0, (sum, book) {
        if (book.bookDetails.volumeInfo?.pageCount != null && book.progress != null) {
          // progress is a double value (like 0.75 for 75%)
          final pagesReadForBook = book.bookDetails.volumeInfo!.pageCount! * book.progress!;
          return sum + pagesReadForBook;
        }
        return sum;
      }).round();

      final readingDates = _extractReadingDates(books);
      final currentStreak = _calculateCurrentStreak(readingDates);
      final longestStreak = _calculateLongestStreak(readingDates);



      emit(DashboardSuccess(
        books: books,
        totalBooks: books.length,
        finishedBooks: finishedBooks,
        goal: readingGoal.goal > 0 ? readingGoal.goal : 12,
        currentlyReading: currentlyReading,
        totalPagesRead: totalPagesRead,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        monthlyReadingData: _generateMonthlyReadingData(books),
        timeFilter: _currentFilter,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  String _currentFilter = '6M';
  List<MonthlyReadingData> _allMonthlyData = [];

  // Add these methods to your DashboardCubit
  List<MonthlyReadingData> _generateMonthlyReadingData(List<UserBook> books) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthlyData = <MonthlyReadingData>[];

    // Get last 6 months
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthName = months[monthDate.month - 1];

      // Calculate pages read for this month
      final pagesThisMonth = books.fold<int>(0, (total, book) {
        if (book.updatedDate != null &&
            book.updatedDate!.year == monthDate.year &&
            book.updatedDate!.month == monthDate.month &&
            book.bookDetails.volumeInfo?.pageCount != null &&
            book.progress != null) {
          return total + (book.bookDetails.volumeInfo!.pageCount! * book.progress!).round();
        }
        return total;
      });

      monthlyData.add(MonthlyReadingData(monthName, pagesThisMonth,monthDate));
    }

    _allMonthlyData = monthlyData; // Store all data for filtering
    return _filterMonthlyData(monthlyData, _currentFilter);
  }

  // Extract unique dates when reading activity occurred
  Set<DateTime> _extractReadingDates(List<UserBook> books) {
    final readingDates = <DateTime>{};

    for (final book in books) {
      if (book.updatedDate != null) {
        // Normalize to date only (remove time)
        final dateOnly = DateTime(
            book.updatedDate!.year,
            book.updatedDate!.month,
            book.updatedDate!.day
        );
        readingDates.add(dateOnly);
      }
    }

    return readingDates;
  }

  List<MonthlyReadingData> _filterMonthlyData(List<MonthlyReadingData> data, String filter) {
    if (filter == '6M') {
      return data.length > 6 ? data.sublist(data.length - 6) : data;
    } else if (filter == '1Y') {
      return data;
    }
    return data;
  }

  void changeTimeFilter(String filter) {
    _currentFilter = filter;
    if (state is DashboardSuccess) {
      final currentState = state as DashboardSuccess;
      emit(currentState.copyWith(
        monthlyReadingData: _filterMonthlyData(_allMonthlyData, filter),
        timeFilter: filter,
      ));
    }
  }

// Calculate current consecutive streak
  int _calculateCurrentStreak(Set<DateTime> readingDates) {
    if (readingDates.isEmpty) return 0;

    final sortedDates = readingDates.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = currentDate;

    // Check if user read today or yesterday to start streak
    if (sortedDates.contains(checkDate)) {
      streak = 1;
    } else {
      final yesterday = checkDate.subtract(const Duration(days: 1));
      if (sortedDates.contains(yesterday)) {
        streak = 1;
        checkDate = yesterday; // Start from yesterday
      } else {
        return 0; // No reading today or yesterday
      }
    }

    // Check previous consecutive days
    DateTime previousDate = checkDate.subtract(const Duration(days: 1));
    while (sortedDates.contains(previousDate)) {
      streak++;
      previousDate = previousDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // Calculate longest historical streak
  int _calculateLongestStreak(Set<DateTime> readingDates) {
    if (readingDates.isEmpty) return 0;

    final sortedDates = readingDates.toList()..sort();
    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final previousDate = sortedDates[i - 1];
      final currentDate = sortedDates[i];

      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        // Consecutive days
        currentStreak++;
        longestStreak = max(longestStreak, currentStreak);
      } else if (difference > 1) {
        // Gap in reading, reset current streak
        currentStreak = 1;
      }
      // If difference == 0, it's the same day, so we skip
    }

    return longestStreak;
  }

  Future<void> updateReadingGoal(String userId, int newGoal) async {
    try {
      await repo.updateReadingGoal(newGoal);
      await loadUserBooks(userId); // reload with updated goal
    } catch (e) {
      emit(DashboardError("Failed to update reading goal: $e"));
    }
  }


}

