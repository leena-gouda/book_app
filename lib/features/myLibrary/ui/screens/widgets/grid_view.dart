import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../home/data/models/book_model.dart';
import '../../../../home/ui/screens/widgets/book_card.dart';


class BookGridView extends StatelessWidget {
  final List<Items> books;

  const BookGridView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 books per row
        crossAxisSpacing: 16.w, // Horizontal spacing between items
        mainAxisSpacing: 16.h, // Vertical spacing between items
        childAspectRatio: 0.65, // Width/Height ratio
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BookCard(books: books[index],);
      },
    );
  }
}