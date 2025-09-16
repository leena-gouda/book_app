import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/data/models/book_model.dart';
import '../../../home/ui/screens/widgets/book_card.dart';
import '../../../myLibrary/ui/cubit/button_cubit.dart';
import '../../../myLibrary/ui/screens/widgets/small_buttons.dart';

class SearchScreen extends StatelessWidget {
  final List<Items> allBooks;

  const SearchScreen({
    super.key,
    required this.allBooks,
  });

  @override
  Widget build(BuildContext context) {
    final query = ValueNotifier<String>("");

    return Scaffold(
      appBar: AppBar(
          title: Text("Search Books".tr()),
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              onChanged: (text) => query.value = text,
              decoration: InputDecoration(
                hintText: "Search by title, author, or genre...".tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 🔘 Genre filters
            _buildGenreFilters(context),

            SizedBox(height: 16.h),

            // 📚 Results
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: query,
                builder: (context, queryValue, _) {
                  return BlocBuilder<ButtonCubit, String>(
                    builder: (context, selectedGenre) {
                      final filteredBooks = allBooks.where((book) {
                        final title = book.volumeInfo?.title?.toLowerCase() ?? "";
                        final authors = (book.volumeInfo?.authors ?? []).join(", ").toLowerCase();
                        final categories = (book.volumeInfo?.categories ?? []).join(", ").toLowerCase();

                        // If query is empty, skip filtering by title/author
                        final matchesQuery = queryValue.isEmpty ||
                            title.contains(queryValue.toLowerCase()) ||
                            authors.contains(queryValue.toLowerCase()) ||
                            categories.contains(queryValue.toLowerCase());

                        // Fix genre matching (split + lowercase)
                        final matchesGenre = selectedGenre == "All" ||
                            (book.volumeInfo?.categories ?? [])
                                .any((c) => c.toLowerCase().split('/')
                                .map((g) => g.trim())
                                .contains(selectedGenre.toLowerCase()));

                        return matchesQuery && matchesGenre;
                      }).toList();


                      if (filteredBooks.isEmpty) {
                        return Center(
                          child: Text(
                            "No books found".tr(),
                            style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                          ),
                        );
                      }


                      return GridView.builder(
                        itemCount: filteredBooks.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 20.h,
                          childAspectRatio: 0.61,
                        ),
                        itemBuilder: (context, index) {
                          return BookkCard(book: filteredBooks[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
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
          orElse: () => MapEntry('All', allBooks.length),
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
    final Map<String, int> genres = {'All': allBooks.length};

    for (var item in allBooks) {
      final bookGenres = item.volumeInfo?.categories ?? [];
      for (var genre in bookGenres) {
        for (var g in genre.split('/')) {
          final clean = g.trim();
          if (clean.isNotEmpty) {
            genres[clean] = (genres[clean] ?? 0) + 1;
          }
        }
      }
    }


    return genres;
  }
}
