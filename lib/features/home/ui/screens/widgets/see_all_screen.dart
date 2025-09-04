import 'package:book_app/features/home/ui/screens/widgets/book_card.dart';
import 'package:book_app/features/myLibrary/ui/cubit/button_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../myLibrary/ui/screens/widgets/book_card.dart';
import '../../../../myLibrary/ui/screens/widgets/grid_view.dart';
import '../../../../myLibrary/ui/screens/widgets/small_buttons.dart';
import '../../../data/models/book_model.dart';
import 'book_list_card.dart';

// Reusable See All Screen
class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Items> items;
  final String filterText;
  final String initialFilter; // Add initial filter option

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.items,
    required this.filterText,
    this.initialFilter = 'All', // Default to 'All'
  });

  @override
  Widget build(BuildContext context) {
    // Initialize the filter state when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ButtonCubit>().selectButton(initialFilter);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title,style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Total items text (same as "All" count)
            // BlocBuilder<ButtonCubit, String>(
            //   builder: (context, selectedGenre) {
            //     final genres = _extractGenresFromBooks();
            //     final totalCount = genres['All'] ?? 0;
            //
            //     return Text(
            //       '$totalCount items',
            //       style: TextStyle(
            //         fontSize: 14.sp,
            //         color: Colors.grey,
            //       ),
            //     );
            //   },
            // ),
            //
            // SizedBox(height: 16.h),
            Text(
              filterText,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),

            // Genre filter chips
            _buildGenreFilters(context),
            SizedBox(height: 8.h),

            // Books grid
            Expanded(child: _buildBooksGrid(context)),
          ],
        ),
      ),

    );
  }

  Widget _buildGenreFilters(BuildContext context) {
    final genres = _extractGenresFromBooks();

    return BlocBuilder<ButtonCubit, String>(
      builder: (context, selectedGenre) {
        final genreEntries = genres.entries.toList();
        final allEntry = genreEntries.firstWhere(
              (entry) => entry.key == 'All',
          orElse: () => MapEntry('All', items.length),
        );

        genreEntries.removeWhere((entry) => entry.key == 'All');
        genreEntries.insert(0, allEntry);

        return SizedBox(

          height: 50.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genreEntries.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final genre = genreEntries[index].key;
              final count = genreEntries[index].value;
              final isSelected = selectedGenre == genre;

              return SmallButtons(
                text: genre,
                circleText: count.toString(),
                circleTextColor: Colors.black,
                hasBorder: true,
                width: 60.w,
                isSelected: isSelected,
                onPressed: () {
                  context.read<ButtonCubit>().selectButton(genre);
                },
              );
            },
          ),
        );
      },
    );
  }

  Map<String, int> _extractGenresFromBooks() {
    final Map<String, int> genres = {'All': items.length};

    // Handle case where items might be empty
    if (items.isEmpty) return genres;

    for (var item in items) {
      try {
        // Adjust this based on your book model structure
        final bookGenres = item.volumeInfo?.categories ?? [];

        for (var genre in bookGenres) {
          genres[genre] = (genres[genre] ?? 0) + 1;
        }
      } catch (e) {
        // Handle potential errors gracefully
        print('Error extracting genres: $e');
      }
    }

    return genres;
  }

  Widget _buildBooksGrid(BuildContext context) {
    return BlocBuilder<ButtonCubit, String>(
      builder: (context, selectedGenre) {
        // Filter books based on selected genre
        List<Items> filteredBooks;

        if (selectedGenre == 'All') {
          filteredBooks = items;
        } else {
          filteredBooks = items.where((book) {
            try {
              return book.volumeInfo?.categories?.contains(selectedGenre) ?? false;
            } catch (e) {
              return false;
            }
          }).toList();
        }

        // Show empty state if no books match the filter
        if (filteredBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64.w,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No books found',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  selectedGenre == 'All'
                      ? 'Try adding some books to your library'
                      : 'No books in the $selectedGenre category',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: filteredBooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 20.h,
            childAspectRatio: 0.61,
          ),
          itemBuilder: (context, index) {
            final filteredBook = filteredBooks[index];
            return BookkCard(book: filteredBook,);
          },
        );
      },
    );
  }
}