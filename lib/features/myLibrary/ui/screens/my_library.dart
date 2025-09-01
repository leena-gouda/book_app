import 'package:book_app/features/myLibrary/ui/screens/widgets/grid_view.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/small_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routing/routes.dart';
import '../../../bookDetails/ui/screens/book_details.dart';
import '../../../bookDetails/ui/screens/widgets/progress_bar.dart';
import '../cubit/button_cubit.dart';
import '../cubit/my_library_cubit.dart';

class MyLibrary extends StatelessWidget {
  const MyLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryCubit = context.read<LibraryCubit>();
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              Text('My Library', style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text("Organize and track your reading collection",
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey, fontWeight: FontWeight.bold)),
              SizedBox(height: 24.h),

              // 🔄 Button Row with Selection Logic
              Expanded(
                child: BlocBuilder<ButtonCubit, String>(
                  builder: (context, selectedStatus) {
                    final statuses = ['All', 'Reading', 'Finished', 'To Read', 'Lists'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: statuses.map((status) {
                              final isSelected = selectedStatus == status;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: SmallButtons(
                                  text: status,
                                  circleText: "", // You can add dynamic counts later
                                  hasBorder: true,
                                  width: 120.w,
                                  isSelected: isSelected,
                                  onPressed: () {
                                    context.read<ButtonCubit>().selectButton(status);
                                    context.read<LibraryCubit>().loadBooks(status);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        Text("Reading Progress", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                        // 📚 Book Grid or Reading List
                        Expanded(
                          child: BlocBuilder<LibraryCubit, LibraryState>(
                            builder: (context, state) {
                              if (state is LibraryLoading) {
                                return Center(child: CircularProgressIndicator());
                              } else if (state is LibraryLoaded) {
                                final books = state.books
                                    .where((e) => e.bookDetails != null && e.status == selectedStatus.toLowerCase())
                                    .toList();

                                if (books.isEmpty) {
                                  return Center(child: Text("No books found"));
                                }

                                if (selectedStatus == 'Reading') {
                                  return SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: books.length,
                                          separatorBuilder: (context, index) => SizedBox(height: 10.h,),
                                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                          itemBuilder: (context, index) {
                                            final book = books[index];
                                            final progress = book.progress ?? 0.0;

                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12.h),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8.r),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => BookDetails.withProgress(book),
                                                              ),
                                                            );
                                                          },
                                                          child: Image.network(
                                                            book.bookDetails.volumeInfo?.imageLinks?.thumbnail ?? 'https://via.placeholder.com/150',
                                                            width: 60.w,
                                                            height: 70.h,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                book.bookDetails.volumeInfo?.title ?? 'Untitled',
                                                                style: TextStyle(
                                                                    fontSize: 16.sp, fontWeight: FontWeight.bold),
                                                              ),
                                                              Text(
                                                                book.bookDetails.volumeInfo?.authors?.join(', ') ??
                                                                    'Unknown Author',
                                                                style: TextStyle(
                                                                    fontSize: 14.sp, color: Colors.grey[600]),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 12.h),
                                                    ReadingProgressBar(
                                                      currentProgress: book.progress ?? 0.0,
                                                      onProgressChanged: (newProgress) {
                                                        libraryCubit.updateBookProgress(book.bookId, newProgress);

                                                        if (newProgress == 0) {
                                                          libraryCubit.moveBookToCategory(book.bookId, 'to_read');
                                                        } else if (newProgress == 100) {
                                                          libraryCubit.moveBookToCategory(book.bookId, 'finished');
                                                        } else {
                                                          libraryCubit.moveBookToCategory(book.bookId, 'reading');
                                                        }

                                                        Future.microtask(() {
                                                          libraryCubit.loadBooks(selectedStatus.toLowerCase());
                                                        });

                                                      },

                                                      book: book.bookDetails,
                                                      bookId: book.bookDetails.id,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.5, // or any fixed height
                                          child: BookGridView(books: books),
                                        )

                                      ],
                                    ),
                                  );
                                }

                                return BookGridView(books: books);
                              } else if (state is LibraryError) {
                                return Center(child: Text("Error: ${state.message}"));
                              }
                              return Container();
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
