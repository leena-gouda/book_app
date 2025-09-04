import 'package:book_app/features/bookLists/ui/cubit/list_cubit.dart';
import 'package:book_app/features/bookLists/ui/screens/widgets/list_gridview.dart';
import 'package:book_app/features/myLibrary/data/models/user_book_model.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/grid_view.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/small_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../bookDetails/ui/screens/book_details.dart';
import '../../../bookDetails/ui/screens/widgets/progress_bar.dart';
import '../../../bookLists/data/repos/list_repo.dart';
import '../../../bookLists/ui/screens/widgets/add_to_list.dart';
import '../cubit/button_cubit.dart';
import '../cubit/my_library_cubit.dart';

class MyLibrary extends StatelessWidget {
  const MyLibrary({super.key});


  @override
  Widget build(BuildContext context) {
    // In your widget or somewhere accessible

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

              BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, state) {
                  final libraryCubit = context.read<LibraryCubit>();
                  final allBooks = libraryCubit.getAllBooks();
                  final listsState = context.read<ListCubit>().state;
                  final listCount = listsState is ListLoaded ? listsState.lists.length : 0;
                  print("All Books Count: ${allBooks.length}");
                  print("All Lists Count: ${listCount}");

                  Map<String, int> categoryCounts = {
                    'All': allBooks.length,
                    'Reading': allBooks.where((e) => e.status == 'reading').length,
                    'Finished': allBooks.where((e) => e.status == 'finished').length,
                    'To Read': allBooks.where((e) => e.status == 'to_read').length,
                    // 'Lists': listsCubit.state is ListLoaded ? (listsCubit.state as ListLoaded).lists.length : 0,
                    'Lists': listCount,
                  };

                  // 🔄 Button Row with Selection Logic
                  return Expanded(
                    child: BlocBuilder<ButtonCubit, String>(
                      builder: (context, selectedStatus) {
                        final statuses = ['All', 'Reading', 'Finished', 'To Read', 'Lists'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child:  Row(
                                children: statuses.map((status) {
                                  final isSelected = selectedStatus == status;
                                  final count = categoryCounts[status] ?? 0;
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: SmallButtons(
                                      text: status,
                                      circleText: count.toString(),
                                      circleTextColor: Colors.black,
                                      hasBorder: true,
                                      width: 120.w,
                                      isSelected: isSelected,
                                      onPressed: () {
                                        context.read<ButtonCubit>().selectButton(status);
                                        if (status != 'Lists') {
                                          context.read<LibraryCubit>().loadBooks(status);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),

                            ),
                            SizedBox(height: 24.h),

                            // Only show "Reading Progress" title for Reading section
                            if (selectedStatus == 'Reading')
                              Text("Reading Progress", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),

                            SizedBox(height: selectedStatus == 'Reading' ? 16.h : 0),

                            // 📚 Book Grid or Reading List
                            Expanded(
                              child: selectedStatus == 'Lists'
                              ? _buildListsTab(context) // Separate method for Lists tab
                                  : _buildBooksTab(context, selectedStatus),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildListsTab(BuildContext context) {
    return BlocBuilder<ListCubit, ListState>(
      builder: (context, state) {
        if (state is ListLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is ListError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is ListLoaded) {
          final lists = state.lists;
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No lists yet', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Create your first list to organize books',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showCreateListDialog(context),
                    child: Text('Create New List'),
                  ),
                ],
              ),
            );
          }
          return ListGridview(lists: lists);
        }
        return Container();
      },
    );
  }

  Widget _buildBooksTab(BuildContext context, String selectedStatus) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state is LibraryLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (state is LibraryLoaded) {
          // Filter books based on selected status
          final books = selectedStatus == 'All'
              ? state.books.where((e) => e.bookDetails != null).toList()
              : state.books.where((e) => e.bookDetails != null &&
              (selectedStatus == 'Reading' ? e.status == 'reading' :
              selectedStatus == 'Finished' ? e.status == 'finished' :
              selectedStatus == 'To Read' ? e.status == 'to_read' : true))
              .toList();

          if (books.isEmpty) {
            return Center(child: Text("No books found"));
          }

          // Special layout for "Reading" status with progress bars
          if (selectedStatus == 'Reading') {
            return ListView.separated(
              itemCount: books.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              itemBuilder: (context, index) {
                final book = books[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(12.w),
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
                              height: 80.h,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  book.bookDetails.volumeInfo?.authors?.join(', ') ??
                                      'Unknown Author',
                                  style: TextStyle(
                                      fontSize: 14.sp, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      ReadingProgressBar(
                        currentProgress: book.progress ?? 0.0,
                        onProgressChanged: (newProgress) {
                          context.read<LibraryCubit>().updateBookProgress(book.bookId, newProgress);
                        },
                        book: book.bookDetails,
                        bookId: book.bookId,
                      ),
                    ],
                  ),
                );
              },
            );
          }



          // Grid view for other statuses
          return BookGridView(books: books);
        } else if (state is LibraryError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        return Container();
      },
    );
  }
}