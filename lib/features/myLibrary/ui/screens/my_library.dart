import 'package:book_app/features/myLibrary/ui/cubit/button_cubit.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/grid_view.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/small_buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyLibrary extends StatelessWidget {
  const MyLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ButtonCubit(),
      child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
          ),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SmallButtons(
                              text: 'All',
                              circleText: "7",
                              hasBorder: true,
                              width: 100.w,
                            ),
                            SizedBox(width: 8.w),
                            SmallButtons(
                              text: 'Reading',
                              circleText: "3",
                              hasBorder: true,
                              width: 120.w,
                            ),
                            SizedBox(width: 8.w),
                            SmallButtons(
                              text: 'Finished',
                              circleText: "2",
                              hasBorder: true,
                              width: 130.w,
                            ),
                            SizedBox(width: 8.w),
                            SmallButtons(
                              text: 'To Read',
                              circleText: "2",
                              hasBorder: true,
                              width: 130.w,
                            ),
                            SizedBox(width: 8.w),
                            SmallButtons(
                              text: 'Lists',
                              circleText: "2",
                              hasBorder: true,
                              width: 130.w,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Expanded(
                        child: BookGridView(books: books),
                      ),
                    ]
                ),
              )
          )
      ),
    );
  }
}