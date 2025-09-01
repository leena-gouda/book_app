import 'package:book_app/features/myLibrary/data/models/user_book_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../home/data/models/book_model.dart';
import 'book_card.dart';

class BookGridView extends StatelessWidget {
  final List<UserBook> books;

  const BookGridView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: books.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 20.h,
        childAspectRatio: 0.61,
      ),
      itemBuilder: (context, index) {
        final userBook = books[index];
        final status = userBook.status;

        return BookCard(userBook: userBook, status: status);
      },
    );

  }
}
