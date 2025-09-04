import 'package:book_app/core/theme/app_colors.dart';
import 'package:book_app/core/widgets/custom_button.dart';
import 'package:book_app/features/Reviews/ui/screens/Widgets/custom_review_section.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_button.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_rating_stars.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/progress_bar.dart';
import 'package:book_app/features/home/data/models/book_model.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_description.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Reviews/ui/cubit/review_cubit.dart';
import '../../../bookLists/data/repos/list_repo.dart';
import '../../../bookLists/ui/cubit/list_cubit.dart';
import '../../../bookLists/ui/screens/widgets/add_to_list.dart';
import '../../../myLibrary/data/models/user_book_model.dart';
import '../../../myLibrary/ui/cubit/my_library_cubit.dart';

class BookDetails extends StatelessWidget {
  final Items book;
  final UserBook? userBook;
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  //final ValueNotifier<bool> isCurrentlyReading  = ValueNotifier(false);
  final ValueNotifier<String> currentStatus; // Change to track status
  //final ValueNotifier<double> readingProgress; // Make this instance-specific


  BookDetails({super.key, required this.book, double? progress, this.userBook})
      : currentStatus = ValueNotifier(userBook?.status ?? 'none');

  static Widget withProgress(UserBook book) {
    return BookDetails(book: book.bookDetails,userBook: book,);
  }

  @override
  Widget build(BuildContext context) {
    final reviewCubit = context.read<ReviewCubit>();
    final bookId = book.id ?? 'unknown_id';
    print('Using bookId: $bookId');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewCubit.loadReviews(bookId);
    });
    // currentStatus.addListener(() {
    //   if (currentStatus.value == 'reading' && readingProgress.value == 0.0) {
    //     // Set a default progress if switching to reading with 0 progress
    //     readingProgress.value = 0.1;
    //   }
    // });
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0.r),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 395.w,
                  height: 336.h,
                  color: Colors.grey[300],
                  child: book.volumeInfo?.imageLinks?.thumbnail != null
                      ? Image.network(
                    book.volumeInfo?.imageLinks?.thumbnail ?? '',
                    height: 280.h,
                    width: 180.w,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 280.h,
                    width: 180.w,
                    color: Colors.grey[300],
                    child: Icon(
                        Icons.book, size: 100.h, color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 20.h),
                // Container(
                //   width: 150.w,
                //   height: 32.h,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(18.r),
                //     border: Border.all(color: AppColor.black),
                //   ),
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Icon(Icons.star, color: AppColor.primaryColor,
                //               size: 20.h),
                //           SizedBox(width: 4.w),
                //           Text(
                //             book.volumeInfo?.categories?.isNotEmpty == true
                //                 ? book.volumeInfo!.categories!.first
                //                 : 'No Category', style: TextStyle(fontSize: 16
                //               .sp, fontWeight: FontWeight.w500),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                //SizedBox(height: 10.h,),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(book.volumeInfo?.title ?? 'No Title', style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.bold,)),
                      Text(book.volumeInfo?.authors?.join(', ') ?? 'Unknown Author',
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]
                          )
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomRatingStars(rating: book.volumeInfo?.averageRating ?? 0),
                          SizedBox(width: 5.w,),
                          Text("${book.volumeInfo?.averageRating ?? '0'}"),
                          SizedBox(width: 4.w),
                          Text("(${book.volumeInfo?.ratingsCount ?? '0'} reviews)"),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: 395.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.9),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First row of buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustButton(
                              text: "Want to Read",
                              textColor: AppColor.black,
                              iconData: CupertinoIcons.bookmark,
                              iconColor: AppColor.black,
                              onPressed: () {
                                currentStatus.value = 'to_read'; // Update the status

                                context.read<LibraryCubit>().setBookStatus(bookId, 'to_read', book: book);

                              },
                              hasBorder: true,
                              borderRadius: 12.r,
                              margin: EdgeInsets.only(right: 8.w),
                            ),
                          ),
                          SizedBox(width: 5.w,),
                          Expanded(
                            child: CustButton(
                              text: "Currently Reading",
                              textColor: AppColor.black,
                              textStyle: TextStyle(fontSize: 12.sp,fontWeight: FontWeight.w900,color: AppColor.black),
                              iconData: CupertinoIcons.book,
                              iconColor: AppColor.black,
                              iconSize: 12.sp,
                              onPressed: () async {
                                currentStatus.value = 'reading'; // Update the status
                                // print("📊 Current progress value: ${readingProgress.value}");
                                // if (readingProgress.value == 0.0) {
                                //   readingProgress.value = 0.1;
                                // }
                                final libraryRepo = context.read<LibraryCubit>().repository;
                                final userId = Supabase.instance.client.auth.currentUser!.id;
                                final exists = await libraryRepo.doesUserBookExist(userId, bookId);
                                print("📋 Book exists in user_books: $exists");

                                context.read<LibraryCubit>().setBookStatus(bookId, 'reading', book: book);
                              },
                              hasBorder: true,
                              borderRadius: 12.r,
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                            ),
                          ),
                          SizedBox(width: 5.w,),
                          Expanded(
                            child: CustButton(
                              text: "Finished",
                              textColor: AppColor.black,
                              //textStyle: TextStyle(fontSize: 12.sp,fontWeight: FontWeight.w900),
                              iconData: CupertinoIcons.checkmark,
                              iconColor: AppColor.black,
                              iconSize: 12.sp,
                              onPressed: () {
                                currentStatus.value = 'finished'; // Update the status

                                context.read<LibraryCubit>().markAsFinished(bookId, book: book);
                              },
                              hasBorder: true,
                              borderRadius: 12.r,
                              margin: EdgeInsets.only(left: 8.w),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // ValueListenableBuilder<String>(
                      //     valueListenable: currentStatus,
                      //     builder: (context, status, child) {
                      //       // Only show progress bar if status is 'reading'
                      //       if (status == 'reading') {
                      //         return Padding(
                      //           padding: EdgeInsets.symmetric(vertical: 12.h),
                      //           child: ReadingProgressBar(
                      //               currentProgress: readingProgress.value ,
                      //               onProgressChanged: (newProgress) {
                      //                 readingProgress.value = newProgress;
                      //                 context.read<LibraryCubit>().updateBookProgress(bookId, readingProgress.value);
                      //               },
                      //               book: book,
                      //               bookId: bookId
                      //           ),
                      //         );
                      //       } else {
                      //         return SizedBox.shrink(); // Hide progress bar
                      //       }
                      //     }
                      // ),

                      ValueListenableBuilder<String>(
                          valueListenable: currentStatus,
                          builder: (context, status, child) {
                            if (status == 'reading') {
                              // Get the current progress from the library cubit
                              final libraryCubit = context.read<LibraryCubit>();
                              final userBook = libraryCubit.getUserBook(bookId);
                              final currentProgress = userBook?.progress ?? 0.1;

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: ReadingProgressBar(
                                  currentProgress: currentProgress,
                                  onProgressChanged: (newProgress) {
                                    // Update progress in the library cubit
                                    print("📊 Progress changed to: $newProgress");
                                    libraryCubit.updateBookProgress(bookId, newProgress);
                                    if (currentStatus.value != 'reading') {
                                      currentStatus.value = 'reading';
                                    }
                                  },
                                  book: book,
                                  bookId: bookId,
                                ),
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          }
                      ),

                      SizedBox(height: 12.h,),
                      // Add to List button
                      CustButton(
                        text: "Add to List",
                        iconData: CupertinoIcons.plus,
                        onPressed: () => _showAddToListBottomSheet(context, book),
                        hasBorder: true,
                        borderRadius: 12.r,
                        width: 390.w,
                        textColor: AppColor.black,
                        iconColor: AppColor.black,
                        margin: EdgeInsets.symmetric(),

                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: 395.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.9),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("About this book", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp)),
                      SizedBox(height: 12.h),
                      Text(
                        book.volumeInfo?.description ?? 'No Description',
                        style: TextStyle(
                            fontSize: 16.sp, color: Colors.black54),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Pages", text2: book.volumeInfo?.pageCount ?.toString() ?? 'Unknown'),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Published", text2: book.volumeInfo?.publishedDate ?? 'Unknown'),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Publisher", text2: book.volumeInfo?.publisher ?? 'Unknown'),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Genre", text2: book.volumeInfo?.categories?.first ?? 'Unknown'),
                      SizedBox(height: 12.h,),
                      CustomButton(text: "More Details", onPressed: (){_showBookDetails(context);},iconData: CupertinoIcons.info,backgroundColor: Colors.grey[300],textColor: CupertinoColors.systemBlue,iconColor: CupertinoColors.systemBlue,),
                    ],
                  ),
                ),
                SizedBox(height: 12.h,),
                Container(
                  width: 395.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.9),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CustomReviewSection(bookId: bookId,),
                )
                //Divider(color: Colors.grey, height: 8.h,),
                // SizedBox(height: 20.h),
                // Container(
                //   width: 395.w,
                //   height: 264.h,
                //   padding: EdgeInsets.only(left: 16.w),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       CustomDescription(text1: "Author",
                //           text2: book.volumeInfo?.authors?.join(', ') ??
                //               'Unknown'),
                //       SizedBox(height: 12.h),
                //       CustomDescription(text1: "Publisher",
                //           text2: book.volumeInfo?.publisher ?? 'Unknown'),
                //       SizedBox(height: 12.h),
                //       CustomDescription(text1: "Published Date",
                //           text2: book.volumeInfo?.publishedDate ?? 'Unknown'),
                //       SizedBox(height: 12.h),
                //       CustomDescription(text1: "Page Count",
                //           text2: book.volumeInfo?.pageCount?.toString() ??
                //               'Unknown'), SizedBox(height: 12.h),
                //       CustomDescription(text1: "Language",
                //           text2: book.volumeInfo?.language ?? 'Unknown'),
                //       SizedBox(height: 12.h,),
                //       CustomButton(text: "View more detail",
                //           onPressed: () {
                //             _showBookDetails(context);
                //           },
                //           textColor: AppColor.primaryColor,
                //           borderRadius: 18.r,
                //           backgroundColor: AppColor.white,
                //           hasBorder: true),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 12.h),
                // Divider(color: Colors.grey, height: 8.h,),
                // Container(
                //   width: 395.w,
                //   height: 210.h,
                //   padding: EdgeInsets.only(left: 16.w),
                //   child: Column(
                //     children: [
                //       Align(
                //         alignment: Alignment.centerLeft,
                //         child: Text("Description", style: TextStyle(
                //             fontSize: 18.sp, fontWeight: FontWeight.bold)),
                //       ),
                //       SizedBox(height: 12.h),
                //       ValueListenableBuilder<bool>(
                //           valueListenable: isExpanded,
                //           builder: (context, expanded, _) {
                //             return Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   book.volumeInfo?.description ??
                //                       'No Description',
                //                   maxLines: expanded ? null : 3,
                //                   overflow: expanded
                //                       ? TextOverflow.visible
                //                       : TextOverflow.ellipsis,
                //                   style: TextStyle(
                //                       fontSize: 14.sp, color: Colors.black54),
                //                 ),
                //                 SizedBox(height: 8.h),
                //                 if (book.volumeInfo?.description != null &&
                //                     (book.volumeInfo?.description?.length ??
                //                         0) > 100) GestureDetector(
                //                   onTap: () => isExpanded.value = !expanded,
                //                   child: Text(
                //                     expanded ? 'Read less' : 'Read more',
                //                     style: TextStyle(fontSize: 14.sp,
                //                         color: AppColor.primaryColor,
                //                         fontWeight: FontWeight.w500),
                //                   ),
                //                 )
                //               ],
                //             );
                //           }
                //       )
                //     ],
                //   ),
                // ),
                // Divider(color: Colors.grey, height: 8.h,),
                //
                // Container(
                //   width: 395.w,
                //   height: 362.h,
                //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                //   child: StreamBuilder<List<Map<String, dynamic>>>(
                //     stream: reviewCubit.getReviews(bookId),
                //     builder: (context, snapshot) {
                //       if (snapshot.connectionState == ConnectionState.waiting) {
                //         return Center(child: CircularProgressIndicator());
                //       }
                //       if (!snapshot.hasData || snapshot.data!.isEmpty) {
                //         return Center(
                //           child: Text(
                //             'No reviews yet',
                //             style: TextStyle(fontSize: 14.sp),
                //           ),
                //         );
                //       }
                //
                //       final reviews = snapshot.data!;
                //
                //       return Column(
                //         children: reviews.map((data) {
                //           return ListTile(
                //             title: Text(data['userName'] ?? 'Anonymous'),
                //             subtitle: Text(data['comment'] ?? ''),
                //             trailing: Text(
                //                 '${data['rating']?.toStringAsFixed(1) ??
                //                     '0'}/5'),
                //           );
                //         }).toList(),
                //       );
                //     },
                //   ),
                // ),
                // SizedBox(height: 20.h),
                // CustomButton(text: "Add Review", onPressed: () {
                //   //reviewCubit.showAddReviewDialog(context, bookId);
                // },
                //     textColor: AppColor.white,
                //     borderRadius: 18.r,
                //     backgroundColor: AppColor.primaryColor,
                //     hasBorder: false
                // ),
              ],
            ),
          ),
        )
    );
  }


  void _showBookDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isbn13 = book.volumeInfo?.industryIdentifiers?.firstWhere(
              (id) => id.type == 'ISBN_13',
              orElse: () => IndustryIdentifiers(),
        ).identifier;
        final isbn = book.volumeInfo?.industryIdentifiers
            ?.firstWhere(
              (id) => id.type == 'ISBN_13',
          orElse: () => book.volumeInfo?.industryIdentifiers
              ?.firstWhere(
                (id) => id.type == 'ISBN_10',
            orElse: () => IndustryIdentifiers(),
          ) ?? IndustryIdentifiers(),
        )
            .identifier;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Book Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),),
                  Spacer(),
                  IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(CupertinoIcons.xmark))
                ],
              ),
              Divider(thickness: 4,color: Colors.grey[300]),
              SizedBox(height: 16.h),
              CustomDescription(text1: "Title", text2: book.volumeInfo?.title ?? 'No Title'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Author", text2: book.volumeInfo?.authors?.join(', ') ?? 'Unknown'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "ISBN", text2: isbn13 ?? isbn ?? 'No ISBN'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Publisher", text2: book.volumeInfo?.publisher ?? 'No publisher'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Published Date", text2: book.volumeInfo?.publishedDate ?? 'No published date'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Page Count", text2: book.volumeInfo?.pageCount?.toString() ?? 'No page count'),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Language", text2: book.volumeInfo?.language ?? 'No language'),
              SizedBox(height: 16.h,),
              // ElevatedButton(
              //   onPressed: () => Navigator.pop(context),
              //   child: Text('Close'),
              // ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToListBottomSheet(BuildContext context, Items book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return  AddToListBottomSheet(book: book);
      },
    );
  }
}