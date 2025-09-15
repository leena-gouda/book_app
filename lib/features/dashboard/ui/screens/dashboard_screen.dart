import 'dart:math';

import 'package:book_app/features/dashboard/ui/screens/widgets/reading_activity_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../bookDetails/ui/screens/book_details.dart';
import '../../../bookDetails/ui/screens/widgets/progress_bar.dart';
import '../../../home/data/models/book_model.dart';
import '../../../home/ui/cubit/home_cubit.dart';
import '../../../myLibrary/ui/cubit/my_library_cubit.dart';
import '../../../searchScreen/ui/screens/search_screen.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    context.read<DashboardCubit>().loadUserBooks(userId);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        )
            : null,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardError) {
            return Center(child: Text("Error: ${state.message}"));
          } else if (state is DashboardSuccess) {
            final progress = state.goal > 0
                ? state.finishedBooks / state.goal
                : 0.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Reading Dashboard",
                        style: TextStyle(
                            fontSize: 24.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20.h),
                    Text("Track your reading progress and stats here.",
                        style: TextStyle(
                            fontSize: 16.sp, color: AppColor.textGray)),
                    SizedBox(height: 20.h),
              
                    // 📊 Stats card
                    Container(
                      width: double.infinity,
                      height: 200.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("2025 Reading Goal",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.sp)),
                              const Spacer(),
                              Text(
                                "${state.finishedBooks}/${state.goal} books",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.primaryColor,
                                ),
                              ),
              
                            ],
                          ),
                          SizedBox(height: 12.h),
                          LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 12.h,
                            borderRadius: BorderRadius.circular(8.r),
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(AppColor.primaryColor),
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColor.primaryColor),
                                onPressed: () async {
                                  final controller = TextEditingController();
                                  final newGoal = await showDialog<int>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Set Reading Goal"),
                                      content: TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(hintText: "Enter goal for ${DateTime.now().year}"),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                                        ElevatedButton(
                                          onPressed: () {
                                            final val = int.tryParse(controller.text);
                                            Navigator.pop(context, val);
                                          },
                                          child: Text("Save"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (newGoal != null) {
                                    context.read<DashboardCubit>().updateReadingGoal(userId, newGoal);
                                  }
                                },
                              ),
                              Spacer(),
                              Text(
                                  "${progress*100} %",
                                  style: TextStyle(
                                      fontSize: 20.sp,
                                      color: AppColor.primaryColor ,
                                      fontWeight: FontWeight.bold
                                  )
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text("Keep going! You're making great progress.",
                              style: TextStyle(
                                  fontSize: 16.sp, color: AppColor.textGray,fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: (){
                            // Get books from HomeCubit
                            final homeState = context.read<HomeCubit>().state;
                            if (homeState is HomeSuccess) {
                              final List<Items> allBooks = [
                                ...homeState.newReleases ?? [],
                                ...homeState.trendingBooks ?? [],
                                ...homeState.noteworthyBooks ?? [],
                              ];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(allBooks: allBooks,),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Column(
                              children: [
                                Icon(Icons.search, size: 40.h, color: Colors.blue),
                                SizedBox(height: 8.h),
                                Text("Find Books", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
              
                          ),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: (){},
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Column(
                              children: [
                                Icon(Icons.emoji_events_sharp, size: 40.h, color: Colors.amber),
                                SizedBox(height: 8.h),
                                Text("Achievements", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
              
                          ),
                        ),
                        SizedBox(width: 10.w,),
                        GestureDetector(
                          onTap: (){
                            Navigator.pushNamed(context, Routes.myLibraryScreen);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Column(
                              children: [
                                Icon(Icons.bookmark_outline, size: 40.h, color: AppColor.primaryColor),
                                SizedBox(height: 8.h),
                                Text("My  Library", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 110.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Row(
                              children: [
                                Column(
                                  children: [
                                    Text('${state.currentlyReading}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),),
                                    Text("Currently \n Reading", style: TextStyle(fontSize: 14.sp), textAlign: TextAlign.center,),
                                  ],
                                ),
                                Spacer(),
                                Icon(CupertinoIcons.book_solid,color: AppColor.primaryColor,),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Container(
                            height: 110.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Row(
                              children: [
                                Column(
                                  children: [
                                    Text('${state.finishedBooks}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),),
                                    Text("Books Read", style: TextStyle(fontSize: 14.sp), textAlign: TextAlign.center,),
                                  ],
                                ),
                                Spacer(),
                                Icon(CupertinoIcons.book,color: Colors.blue,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Row(
                              children: [
                                Column(
                                  children: [
                                    Text('${state.totalPagesRead}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),),
                                    Text("Pages Read", style: TextStyle(fontSize: 14.sp), textAlign: TextAlign.center,),
                                  ],
                                ),
                                Spacer(),
                                Icon(Icons.notes,color: Colors.purple,),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child:Row(
                              children: [
                                Column(
                                  children: [
                                    Text('${state.currentStreak}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),),
                                    Text("Day Streak", style: TextStyle(fontSize: 14.sp), textAlign: TextAlign.center,),
                                  ],
                                ),
                                Spacer(),
                                Icon(Icons.local_fire_department_outlined,color: Colors.red,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // In your DashboardScreen, add this after the streak containers:
                    SizedBox(height: 30.h),

                    // Reading Activity Chart
                    Container(
                      width: double.infinity,
                      height: 300.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              "Reading Activity",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ReadingActivityChart(
                            data: state.monthlyReadingData,
                            maxValue: state.monthlyReadingData.isNotEmpty
                                ? state.monthlyReadingData.map((e) => e.pagesRead).reduce(max)
                                : 100, // Default max if no data
                            onFilterChanged: (filter) {
                              context.read<DashboardCubit>().changeTimeFilter(filter);
                            },
                            currentFilter: state.timeFilter,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h,),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Currently Reading",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.sp),),
                          SizedBox(height: 10.h),
                          if (state.books.where((b) => b.status == 'reading').isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Text(
                              "No books currently being read",
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                          else
                            ListView.separated(
                              physics: NeverScrollableScrollPhysics(), // Disable scrolling within ListView
                              shrinkWrap: true, // Important for nested ListView
                              itemCount: state.books.where((b) => b.status == 'reading').length,
                              separatorBuilder: (context, index) => SizedBox(height: 16.h),
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                              itemBuilder: (context, index) {
                                final currentlyReadingBooks = state.books.where((b) => b.status == 'reading').toList();
                                final book = currentlyReadingBooks[index];
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
                                                  fontSize: 16.sp, fontWeight: FontWeight.bold
                                                ),
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
                                      // Replace the progress text with this:
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 12.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(6.r),
                                                  ),
                                                  child: FractionallySizedBox(
                                                    alignment: Alignment.centerLeft,
                                                    widthFactor: book.progress ?? 0.0,
                                                    child: Container(
                                                      height: 12.h,
                                                      decoration: BoxDecoration(
                                                        color: AppColor.primaryColor,
                                                        borderRadius: BorderRadius.circular(6.r),
                                                        gradient: LinearGradient(
                                                          colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                "${(book.progress != null ? (book.progress! * 100) : 0).toStringAsFixed(1)}%",
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: AppColor.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
