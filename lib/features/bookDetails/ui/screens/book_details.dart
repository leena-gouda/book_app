import 'package:book_app/core/theme/app_colors.dart';
import 'package:book_app/core/widgets/custom_button.dart';
import 'package:book_app/features/Reviews/ui/screens/Widgets/custom_review_section.dart';
import 'package:book_app/features/bookDetails/ui/cubit/ebook_cubit.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_button.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_rating_stars.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/ebook_access_dialog.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/ebook_reader_screen.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/progress_bar.dart';
import 'package:book_app/features/home/data/models/book_model.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/custom_description.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routing/routes.dart';
import '../../../Reviews/ui/cubit/review_cubit.dart';
import '../../../bookLists/data/repos/list_repo.dart';
import '../../../bookLists/ui/cubit/list_cubit.dart';
import '../../../bookLists/ui/screens/widgets/add_to_list.dart';
import '../../../myLibrary/data/models/user_book_model.dart';
import '../../../myLibrary/ui/cubit/my_library_cubit.dart';

import 'package:url_launcher/url_launcher_string.dart';

class BookDetails extends StatelessWidget {
  final Items book;
  final UserBook? userBook;
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  //final ValueNotifier<bool> isCurrentlyReading  = ValueNotifier(false);
  final ValueNotifier<String> currentStatus; // Change to track status
  //final ValueNotifier<double> readingProgress; // Make this instance-specific


  BookDetails({super.key, required this.book, double? progress, this.userBook})
      : currentStatus = ValueNotifier(userBook?.status ?? 'none');

  String _fixImageUrl(String url) {
    if (url.isEmpty) return url;

    String fixedUrl = url.replaceFirst('http://', 'https://');
    fixedUrl = fixedUrl.replaceAll('\n', '').replaceAll(' ', '');

    return fixedUrl;
  }

  static Widget withProgress(UserBook book) {
    return BookDetails(book: book.bookDetails,userBook: book,);
  }

  @override
  Widget build(BuildContext context) {
    final reviewCubit = context.read<ReviewCubit>();
    final bookId = book.id ?? 'unknown_id';
    final ebookCubit = context.read<EBookCubit>();

    print('Using bookId: $bookId');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewCubit.loadReviews(bookId);
      ebookCubit.checkEbookAccess(bookId);

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
                if (book.volumeInfo?.imageLinks?.thumbnail != null)
                  Container(
                  alignment: Alignment.center,
                  width: 395.w,
                  height: 336.h,
                  color: Colors.grey[300],
                  child: book.volumeInfo?.imageLinks?.thumbnail != null
                      ? Image.network(
                    _fixImageUrl(book.volumeInfo!.imageLinks!.thumbnail!),
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
                      Text(book.volumeInfo?.title ?? 'No Title'.tr(), style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.bold,)),
                      Text(book.volumeInfo?.authors?.join(', ').tr() ?? 'Unknown Author'.tr(),
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
                          Text("${book.volumeInfo?.averageRating ?? '0'}".tr()),
                          // SizedBox(width: 4.w),
                          // Text("(${book.volumeInfo?.ratingsCount ?? '0'} reviews)"),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                BlocConsumer<EBookCubit, EBookState>(
                  listener: (context, state) {
                    if (state is EBookError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    } else if (state is EBookDownloadUrlReady) {
                      // Handle download - launch URL or show download options
                      _launchDownloadUrl(state.downloadUrl, state.format,context);
                    }
                  },
                  builder: (context, state) {
                    final isEbookAvailable = book.saleInfo?.isEbook == true ||
                        book.accessInfo?.epub?.isAvailable == true ||
                        book.accessInfo?.pdf?.isAvailable == true;
                    return Container(
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
                        children: [
                          Row(
                            children: [
                              Icon(Icons.phone_iphone,color: AppColor.primaryColor,),
                              SizedBox(width: 8.w),
                              Text(
                                isEbookAvailable ? 'Available as eBook'.tr() : 'Not available as eBook'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isEbookAvailable ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),
                          if (isEbookAvailable)...[
                            if (isEbookAvailable) _buildEbookAccessUI(context, book.id ?? '', state),
                              // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     Expanded(
                            //       child: CustButton(
                            //         text: "Read Now",
                            //         onPressed: ()=> _handleEbookAccess(context, bookId, false),
                            //         iconData: CupertinoIcons.book,
                            //         margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            //         textColor: AppColor.black,
                            //         iconColor: AppColor.black,
                            //         hasBorder: true,
                            //         borderRadius: 12.r,
                            //       ),
                            //     ),
                            //     SizedBox(width: 20.w,),
                            //     Expanded(
                            //       child: CustButton(
                            //         text: "Download",
                            //         onPressed: () => _handleEbookAccess(context, bookId, true),
                            //         iconData: Icons.download_sharp,
                            //         margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            //         textColor: AppColor.black,
                            //         iconColor: AppColor.black,
                            //         hasBorder: true,
                            //         borderRadius: 12.r,
                            //       ),
                            //     ),
                            //   ],
                            // ),

                          ]
                        ],
                      ),
                    );
                  },
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
                              text: "Want to Read".tr(),
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
                              text: "Currently Reading".tr(),
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
                              text: "Finished".tr(),
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
                        text: "Add to List".tr(),
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
                      Text("About this book".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp)),
                      SizedBox(height: 12.h),
                      Text(
                        book.volumeInfo?.description?.tr() ?? 'No Description'.tr(),
                        style: TextStyle(
                            fontSize: 16.sp, color: Colors.black54),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Pages".tr(), text2: book.volumeInfo?.pageCount ?.toString().tr() ?? 'Unknown'.tr()),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Published".tr(), text2: book.volumeInfo?.publishedDate?.tr() ?? 'Unknown'.tr()),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Publisher".tr(), text2: book.volumeInfo?.publisher?.tr() ?? 'Unknown'.tr()),
                      SizedBox(height: 12.h),
                      CustomDescription(text1: "Genre".tr(), text2: book.volumeInfo?.categories?.first.tr() ?? 'Unknown'.tr()),
                      SizedBox(height: 12.h,),
                      CustomButton(text: "More Details".tr(), onPressed: (){_showBookDetails(context);},iconData: CupertinoIcons.info,backgroundColor: Colors.grey[300],textColor: AppColor.primaryColor,iconColor: AppColor.primaryColor,),
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
                  Text("Book Details".tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),),
                  Spacer(),
                  IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(CupertinoIcons.xmark))
                ],
              ),
              Divider(thickness: 4,color: Colors.grey[300]),
              SizedBox(height: 16.h),
              CustomDescription(text1: "Title".tr(), text2: book.volumeInfo?.title?.tr() ?? 'No Title'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Author".tr(), text2: book.volumeInfo?.authors?.join(', ').tr() ?? 'Unknown'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "ISBN".tr(), text2: isbn13?.tr() ?? isbn?.tr() ?? 'No ISBN'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Publisher".tr(), text2: book.volumeInfo?.publisher?.tr() ?? 'No publisher'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Published Date".tr(), text2: book.volumeInfo?.publishedDate?.tr() ?? 'No published date'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Page Count".tr(), text2: book.volumeInfo?.pageCount?.toString().tr() ?? 'No page count'.tr()),
              SizedBox(height: 16.h,),
              CustomDescription(text1: "Language".tr(), text2: book.volumeInfo?.language?.tr() ?? 'No language'.tr()),
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

  void _handleEbookAccess(BuildContext context, String bookId, bool isDownload) {
    final ebookCubit = context.read<EBookCubit>();

    // Check access and show appropriate dialog or open eBook
    ebookCubit.checkEbookAccess(bookId).then((_) {
      final state = ebookCubit.state;

      if (state is EBookAccessChecked) {
        if (state.hasAccess) {
          if (isDownload) {
            // Download eBook
            if (state.downloadUrl != null) {
              ebookCubit.openEbook(bookId, customUrl: state.downloadUrl);
            }
          } else {
            // Read eBook
            Navigator.pushNamed(
              context,
              Routes.ebookReaderScreen,arguments: {
                'bookId': bookId,
                'ebookUrl': state.downloadUrl,
              }
            );
          }
        } else {
          // Show purchase dialog
          showDialog(
            context: context,
            builder: (context) => EBookAccessDialog(
              hasAccess: state.hasAccess,
              downloadUrl: state.downloadUrl,
              onPurchase: () => ebookCubit.purchaseEbook(bookId, state.price.toDouble()),
              onDownload: () {
                Navigator.pop(context);
                if (state.downloadUrl != null) {
                  ebookCubit.openEbook(bookId, customUrl: state.downloadUrl);
                }
              }, ebookUrl: state.downloadUrl!, bookTitle: book.volumeInfo?.title ?? 'unknown', bookId: bookId,
            ),
          );
        }
      }
    });
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
  Widget _buildEbookAccessButtons(BuildContext context, String bookId, String? downloadUrl) {
    return BlocConsumer<EBookCubit, EBookState>(
      listener: (context, state) {
        if (state is EBookError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is EBookLoading) {
          return _buildLoadingButton();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CustButton(
                text: "Read Now".tr(),
                onPressed: () => _handleReadNow(context, bookId),
                iconData: CupertinoIcons.book,
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                textColor: AppColor.black,
                iconColor: AppColor.black,
                hasBorder: true,
                borderRadius: 12.r,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: CustButton(
                text: "Download".tr(),
                onPressed: () => _handleDownload(context, bookId, downloadUrl),
                iconData: Icons.download_sharp,
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                textColor: AppColor.black,
                iconColor: AppColor.black,
                hasBorder: true,
                borderRadius: 12.r,
              ),
            ),
          ],
        );
      },
    );
  }
// In your BookDetails widget, add a refresh button or automatic refresh
  void _refreshEbookAccess(BuildContext context, String bookId) {
    final ebookCubit = context.read<EBookCubit>();
    ebookCubit.resetState(); // Clear previous state
    ebookCubit.checkEbookAccess(bookId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refreshing eBook access...'.tr())),
    );
  }

// Call this after purchase completes
  Widget _buildPurchaseButton(BuildContext context, String bookId, double price) {
    return CustButton(
      text: "Purchase (\$${price.toStringAsFixed(2)})".tr(),
      onPressed: () async {
        final ebookCubit = context.read<EBookCubit>();

        // Show loading
        ebookCubit.emit(EBookLoading());

        try {
          await ebookCubit.purchaseEbook(bookId,price.toDouble());

          // Refresh access check AFTER purchase completes
          _refreshEbookAccess(context, bookId);

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Purchase failed: $e').tr()),
          );
        }
      },
      iconData: Icons.shopping_cart,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      textColor: AppColor.white,
      iconColor: AppColor.white,
      backgroundColor: AppColor.primaryColor,
      hasBorder: false,
      borderRadius: 12.r,
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCheckAccessButton(BuildContext context, String bookId) {
    return CustButton(
      text: "Check Access".tr(),
      onPressed: () => context.read<EBookCubit>().checkEbookAccess(bookId),
      iconData: Icons.refresh,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      textColor: AppColor.black,
      iconColor: AppColor.black,
      hasBorder: true,
      borderRadius: 12.r,
    );
  }

  Future<void> _handleReadNow(BuildContext context, String bookId) async {
    final ebookCubit = context.read<EBookCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final bookContent = await ebookCubit.getBookContent(bookId);
      Navigator.pop(context); // Close loading dialog

      if (bookContent['type'] == 'webview') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EBookReaderScreen(
              bookTitle: book.volumeInfo?.title?.tr() ?? 'E-Book'.tr(),
              bookContent: bookContent,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bookContent['message'].tr())),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load book: $e'.tr())),
      );
    }
  }
  void _handleDownload(BuildContext context, String bookId, String? downloadUrl) {
    if (downloadUrl != null) {
      context.read<EBookCubit>().openEbook(bookId, customUrl: downloadUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No download URL available'.tr())),
      );
    }
  }

  Widget _buildEbookAccessUI(BuildContext context, String bookId, EBookState state) {
    if (state is EBookLoading) {
      return _buildLoadingButton();
    } else if (state is EBookAccessChecked) {
      if (state.hasAccess) {
        return Column(
          children: [
            // Read Now button
            CustButton(
              text: "Read Now".tr(),
              onPressed: () => _handleReadNow(context, bookId),
              iconData: CupertinoIcons.book,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              textColor: AppColor.black,
              iconColor: AppColor.black,
              hasBorder: true,
              borderRadius: 12.r,
            ),
            SizedBox(height: 8.h),

            // Download options dropdown
            // if (state.isEpubAvailable || state.isPdfAvailable)
            //   _buildDownloadOptions(context, bookId, state),
          ],
        );
      } else {
        return _buildPurchaseButton(context, bookId, state.price);
      }
    } else if (state is EBookError) {
      return Text(
        state.message.tr(),
        style: TextStyle(color: Colors.red),
      );
    } else {
      return _buildCheckAccessButton(context, bookId);
    }
  }

  Widget _buildDownloadOptions(BuildContext context, String bookId, EBookAccessChecked state) {
    final ebookCubit = context.read<EBookCubit>();

    return PopupMenuButton<String>(
      onSelected: (format) {
        if (format == 'epub' && state.isEpubAvailable) {
          ebookCubit.downloadEpub(bookId);
        } else if (format == 'pdf' && state.isPdfAvailable) {
          ebookCubit.downloadPdf(bookId);
        }
      },
      itemBuilder: (context) => [
        if (state.isEpubAvailable)
          PopupMenuItem(
            value: 'epub',
            child: Text('Download EPUB'.tr()),
          ),
        if (state.isPdfAvailable)
          PopupMenuItem(
            value: 'pdf',
            child: Text('Download PDF'.tr()),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.black),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, size: 20.w),
            SizedBox(width: 8.w),
            Text('Download Options'.tr(), style: TextStyle(fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchDownloadUrl(String? url, String format,BuildContext context) async {
    if (url != null && await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open URL'.tr())),
      );
    }
  }

}