import 'package:book_app/core/theme/app_colors.dart';
import 'package:book_app/core/utils/extensions/navigation_extensions.dart';
import 'package:book_app/core/widgets/custom_text_form_field.dart';
import 'package:book_app/features/auth/login/ui/screens/login_screen.dart';
import 'package:book_app/features/home/ui/cubit/home_cubit.dart';
import 'package:book_app/features/home/ui/cubit/navigation_cubit.dart';
import 'package:book_app/features/home/ui/screens/widgets/book_list_card.dart';
import 'package:book_app/features/home/ui/screens/widgets/see_all_screen.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/book_card.dart';
import 'package:book_app/features/bookDetails/ui/screens/book_details.dart';
import 'package:book_app/features/home/ui/screens/widgets/book_search.dart';
import 'package:book_app/features/home/ui/screens/widgets/custom_home_subtitle.dart';
import 'package:book_app/features/home/ui/screens/widgets/custom_home_title.dart';
import 'package:book_app/features/myLibrary/ui/screens/my_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routing/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, currentTab) {
        return Scaffold(
          appBar: currentTab == 0 ? _buildHomeAppBar(context) : null,
          body: IndexedStack(
            index: currentTab,
            children: [
              _buildHomeContent(), // Home tab
              const Placeholder(), // Search tab - replace with actual screen
              MyLibrary(), // My Books tab - replace with actual screen
              const Placeholder(), // Dashboard tab - replace with actual screen
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context, currentTab),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        debugPrint("State changed: $state");
        if (state is HomeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();

        if (state is HomeLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading books...'),
              ],
            ),
          );
        } else if (state is HomeError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.message,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => cubit.initializeData(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is HomeSuccess) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().initializeData(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Data Toggle (using cubit property instead of state)
                    _buildMockDataToggle(context, cubit),

                    Text(
                      "Welcome back, Reader!",
                      style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Discover your next favorite book",
                      style: TextStyle(fontSize: 18.sp, color: AppColor.textGray),
                    ),
                    SizedBox(height: 20.h),

                    // New Releases Section
                    Row(
                      children: [
                        CustomHomeTitle(text: "New Releases"),
                        const Spacer(),
                        TextButton(onPressed: () {
                          Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                            'title': "New Releases",
                            'items': state.newReleases,
                            'filterText': 'Filter by Genre:',
                            //'numberOfItems': state.newReleases?.length ?? 0,
                          });
                        }, child: Text("See All")),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    CustomHomeSubtitle(text: "Newly released books spanning various genres."),
                    SizedBox(height: 20.h),
                    BookListCard(
                      books: state.newReleases ?? [],
                    ),

                    SizedBox(height: 30.h),

                    // Trending Now Section
                    Row(
                      children: [
                        CustomHomeTitle(text: "Trending Now"),
                        Spacer(),
                        TextButton(onPressed: () {
                          Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                            'title': "Trending Books",
                            'items': state.trendingBooks,
                            'filterText': 'Filter by Genre:',
                            //'numberOfItems': state.trendingBooks?.length ?? 0,
                          });
                        }, child: Text("See All")),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    CustomHomeSubtitle(text: "Books everyone is talking about."),
                    SizedBox(height: 20.h),
                    BookListCard(
                      books: state.trendingBooks ?? [],
                    ),
                    // New & Noteworthy Section
                    SizedBox(height: 30.h),
                  Row(
                      children: [
                        CustomHomeTitle(text: "Recommended"),
                        Spacer(),
                        TextButton(onPressed: () {
                          Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                            'title': "Recommended Books",
                            'items': state.noteworthyBooks,
                            'filterText': 'Filter by Genre:',
                            //'numberOfItems': state.noteworthyBooks?.length ?? 0,
                          });
                        }, child: Text("See All")),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    CustomHomeSubtitle(text: "Editor’s picks and fresh releases worth your time."),
                    SizedBox(height: 20.h),
                    BookListCard(
                      books: state.noteworthyBooks ?? [],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildMockDataToggle(BuildContext context, HomeCubit cubit) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Use Mock Data'),
          value: cubit.isUsingMockData,
          onChanged: (value) {
            cubit.toggleMockData(value);
            cubit.initializeData();
          },
        ),
        if (cubit.isUsingMockData)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Using Sample Data',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(height: 10.h),
      ],
    );
  }

  AppBar _buildHomeAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        'Read Ease',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.primaryColor,
        ),
      ),
      leading: IconButton(
        onPressed: () {},
        icon: Icon(Icons.menu, size: 20.sp),
      ),
      actions: [
        IconButton(
          icon: Icon(CupertinoIcons.bell, size: 20.sp),
          onPressed: () {
            // Handle notification icon press
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            showSearch(
              context: context,
              delegate: BookSearchDelegate(),
            );
          },
        )
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context, int currentTab) {
    return BottomNavigationBar(
      currentIndex: currentTab,
      onTap: (index) => context.read<NavigationCubit>().changeTab(index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColor.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.book_solid),
          label: 'My Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
      ],
    );
  }
}