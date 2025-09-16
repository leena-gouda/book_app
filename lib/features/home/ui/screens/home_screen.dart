import 'package:book_app/core/theme/app_colors.dart';
import 'package:book_app/core/utils/extensions/navigation_extensions.dart';
import 'package:book_app/core/widgets/custom_text_form_field.dart';
import 'package:book_app/features/auth/login/ui/screens/login_screen.dart';
import 'package:book_app/features/dashboard/ui/screens/dashboard_screen.dart';
import 'package:book_app/features/home/ui/cubit/home_cubit.dart';
import 'package:book_app/features/home/ui/cubit/navigation_cubit.dart';
import 'package:book_app/features/home/ui/screens/widgets/book_card.dart';
import 'package:book_app/features/home/ui/screens/widgets/book_list_card.dart';
import 'package:book_app/features/home/ui/screens/widgets/see_all_screen.dart';
import 'package:book_app/features/myLibrary/ui/screens/widgets/book_card.dart';
import 'package:book_app/features/bookDetails/ui/screens/book_details.dart';
import 'package:book_app/features/home/ui/screens/widgets/book_search.dart';
import 'package:book_app/features/home/ui/screens/widgets/custom_home_subtitle.dart';
import 'package:book_app/features/home/ui/screens/widgets/custom_home_title.dart';
import 'package:book_app/features/myLibrary/ui/screens/my_library.dart';
import 'package:book_app/features/profile/ui/screens/profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routing/routes.dart';
import '../../../searchScreen/ui/screens/search_screen.dart';
import '../../data/models/book_model.dart';


extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =  Supabase.instance.client.auth.currentUser?.id;

    return BlocBuilder<NavigationCubit, int>(
      builder: (context, currentTab) {
        return Scaffold(
          appBar: currentTab == 0 ? _buildHomeAppBar(context) : null,
          body: IndexedStack(
            index: currentTab,
            children: [
              _buildHomeContent(), // Home tab
              BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state is HomeSuccess) {
                    return SearchScreen(
                      allBooks: [
                        ...state.newReleases ?? [],
                        ...state.trendingBooks ?? [],
                        ...state.noteworthyBooks ?? [],
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              MyLibrary(),
              DashboardScreen(userId: userId!),
              ProfileScreen(),
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
                Text('Loading books...'.tr()),
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
                  child: Text('Retry'.tr()),
                ),
              ],
            ),
          );
        } else if (state is HomeSuccess) {
          if (cubit.showGenreView) {
            return _buildGenreBooksView(context, state, cubit);
          }
          return _buildNormalHomeView(context, state, cubit);



        }

        return Center(child: Text('No data available'.tr()));
      },
    );
  }

  Widget _buildGenreBooksView(BuildContext context, HomeSuccess state, HomeCubit cubit) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            cubit.showAllBooks(); // This should reset showGenreView to false
          },
        ),
        title: Text(
          cubit.genres[cubit.currentGenreIndex].capitalize(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.books.isEmpty
          ? Center(child: Text('No books found in this genre'.tr()))
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15.w,
            mainAxisSpacing: 15.h,
            childAspectRatio: 0.7,
          ),
          itemCount: state.books.length,
          itemBuilder: (context, index) {
            final book = state.books[index];
            return BookkCard(
              book: book,
            );
          },
        ),
      ),
    );
  }

// Your existing home view (renamed from the original content)
  Widget _buildNormalHomeView(BuildContext context, HomeSuccess state, HomeCubit cubit) {
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().initializeData(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock Data Toggle (using cubit property instead of state)
              // _buildMockDataToggle(context, cubit),

              Text(
                "Welcome back, Reader!".tr(),
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text(
                "Discover your next favorite book".tr(),
                style: TextStyle(fontSize: 18.sp, color: AppColor.textGray),
              ),
              SizedBox(height: 20.h),

              // New Releases Section
              Row(
                children: [
                  CustomHomeTitle(text: "New Releases".tr()),
                  const Spacer(),
                  TextButton(onPressed: () {
                    Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                      'title': "New Releases".tr(),
                      'items': state.newReleases,
                      'filterText': 'Filter by Genre:'.tr(),
                      //'numberOfItems': state.newReleases?.length ?? 0,
                    });
                  }, child: Text("See All".tr())),
                ],
              ),
              SizedBox(height: 5.h),
              CustomHomeSubtitle(text: "Newly released books spanning various genres.".tr()),
              SizedBox(height: 20.h),
              BookListCard(
                books: state.newReleases ?? [],
              ),

              SizedBox(height: 30.h),

              // Trending Now Section
              Row(
                children: [
                  CustomHomeTitle(text: "Trending Now".tr()),
                  Spacer(),
                  TextButton(onPressed: () {
                    Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                      'title': "Trending Books".tr(),
                      'items': state.trendingBooks,
                      'filterText': 'Filter by Genre:'.tr(),
                      //'numberOfItems': state.trendingBooks?.length ?? 0,
                    });
                  }, child: Text("See All".tr())),
                ],
              ),
              SizedBox(height: 5.h),
              CustomHomeSubtitle(text: "Books everyone is talking about.".tr()),
              SizedBox(height: 20.h),
              BookListCard(
                books: state.trendingBooks ?? [],
              ),
              // New & Noteworthy Section
              SizedBox(height: 30.h),
            Row(
                children: [
                  CustomHomeTitle(text: "Recommended".tr()),
                  Spacer(),
                  TextButton(onPressed: () {
                    Navigator.pushNamed(context, Routes.seeAllScreen, arguments: {
                      'title': "Recommended Books".tr(),
                      'items': state.noteworthyBooks,
                      'filterText': 'Filter by Genre:'.tr(),
                      //'numberOfItems': state.noteworthyBooks?.length ?? 0,
                    });
                  }, child: Text("See All".tr())),
                ],
              ),
              SizedBox(height: 5.h),
              CustomHomeSubtitle(text: "Editor’s picks and fresh releases worth your time.".tr()),
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
        'Read Ease'.tr(),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.primaryColor,
        ),
      ),
      leading: PopupMenuButton<String>(
        icon: Icon(Icons.menu, size: 20.sp),
        onSelected: (genre) {
          // Get the index of the selected genre
          final index = context.read<HomeCubit>().genres.indexOf(genre);
          if (index != -1) {
            context.read<HomeCubit>().getBooksByGenre(genre, index);
          }
        },
        itemBuilder: (BuildContext context) {
          return context.read<HomeCubit>().genres.map((String genre) {
            return PopupMenuItem<String>(
              value: genre,
              child: Text(genre.capitalize()), // Add capitalize extension if needed
            );
          }).toList();
        },
      ),
      actions: [
        // IconButton(
        //   icon: Icon(CupertinoIcons.bell, size: 20.sp),
        //   onPressed: () {
        //     // Handle notification icon press
        //   },
        // ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
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
                  builder: (_) => SearchScreen(allBooks: allBooks),
                ),
              );
            }

          },
        ),

        IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          onPressed: () {
              Navigator.pushNamed(
                  context,
                  Routes.dashboardScreen,arguments: {
                    'userId': Supabase.instance.client.auth.currentUser?.id,
                  }
              );
          },
        ),


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
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Search'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.book_solid),
          label: 'My Books'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile'.tr(),
        ),
      ],
    );
  }
}