import 'dart:ui' as ui;

import 'package:book_app/core/network/dio_client.dart';
import 'package:book_app/features/Reviews/data/repo/review_repo.dart';
import 'package:book_app/features/Reviews/ui/cubit/review_cubit.dart';
import 'package:book_app/features/Reviews/ui/cubit/user_review_cubit.dart';
import 'package:book_app/features/auth/login/ui/cubit/login_cubit.dart';
import 'package:book_app/features/auth/signup/ui/cubit/signup_cubit.dart';
import 'package:book_app/features/bookDetails/data/repos/ebook_repo.dart';
import 'package:book_app/features/bookDetails/ui/cubit/ebook_cubit.dart';
import 'package:book_app/features/bookLists/data/repos/list_repo.dart';
import 'package:book_app/features/bookLists/ui/cubit/list_cubit.dart';
import 'package:book_app/features/dashboard/data/repo/dashboard_repo.dart';
import 'package:book_app/features/dashboard/ui/cubit/dashboard_cubit.dart';
import 'package:book_app/features/home/data/repos/book_api_repo.dart';
import 'package:book_app/features/home/data/repos/mockrepo.dart';
import 'package:book_app/features/home/data/repos/nyt_books_repo.dart';
import 'package:book_app/features/home/ui/cubit/home_cubit.dart';
import 'package:book_app/features/home/ui/screens/home_screen.dart';
import 'package:book_app/features/myLibrary/data/repos/library_repo.dart';
import 'package:book_app/features/myLibrary/ui/cubit/button_cubit.dart';
import 'package:book_app/features/myLibrary/ui/cubit/my_library_cubit.dart';
import 'package:book_app/features/profile/data/repos/profile_repo.dart';
import 'package:book_app/features/profile/ui/cubit/profile_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_bloc_observer.dart';
import 'core/routing/app_router.dart';
import 'core/routing/routes.dart';
import 'features/home/ui/cubit/navigation_cubit.dart';
import 'features/profile/ui/cubit/theme_cubit.dart';

bool isLogin = true;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {


    const supabaseUrl = 'https://xfgxabuovlviqjixipib.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmZ3hhYnVvdmx2aXFqaXhpcGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMTkyOTksImV4cCI6MjA3MTg5NTI5OX0.-FrH7aiXIDuvxwY69kaxHHZ2OeTKaDDyt5kjrTprnsw'; // your actual anon key

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    final libraryRepo = LibraryRepository();
    await libraryRepo.fixMissingUserBooks();

    Bloc.observer = AppBlocObserver();

    await isLoggedIn();

    runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(appRouter: AppRouter())));
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    runApp(const ErrorApp() as Widget);
  }
}


class ErrorApp {
  const ErrorApp();
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(428, 926),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (context) {
            final dioClient = DioClient();
            final booksRepo = BooksApiRepo(dioClient);
            final mock = MockBooksRepo();
            final nyt = NYTBooksRepo(dioClient);
            return HomeCubit(apiRepo: booksRepo, mockRepo: mock, nytBooksRepo: nyt)..initializeData();
          }),
          BlocProvider<NavigationCubit>(create: (context) => NavigationCubit()),
          BlocProvider<SignupCubit>(create: (context) => SignupCubit()),
          BlocProvider<LoginCubit>(create: (context) => LoginCubit()),
          BlocProvider<ReviewCubit>(create: (context) => ReviewCubit(ReviewRepository())),
          BlocProvider<LibraryCubit>(create: (context) => LibraryCubit(LibraryRepository())..loadBooks("All")),
          BlocProvider<ButtonCubit>(create: (context) => ButtonCubit()),
          BlocProvider<ListCubit>(create: (context) => ListCubit(ListRepository())..loadLists()),
          BlocProvider<DashboardCubit>(create: (context) => DashboardCubit(DashboardRepo())),
          BlocProvider<EBookCubit>(create: (context) => EBookCubit(EBookRepository())),
          BlocProvider<ProfileCubit>(create: (context) => ProfileCubit(ProfileRepository())..loadProfile()),
          BlocProvider<UserReviewsCubit>(create: (context) => UserReviewsCubit(ReviewRepository())..loadUserReviews()),
          BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),

        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
  builder: (context, themeMode) {
    return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: HomeScreen(),
          builder: (context, child) {
            return Directionality(
              textDirection: context.locale.languageCode == 'ar'
                  ? ui.TextDirection.rtl
                  : ui.TextDirection.ltr,
              child: child!,
            );
          },
          navigatorKey: navigatorKey,
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          //initialRoute: Routes.signupsScreen,
          initialRoute: isLogin ? Routes.homeScreen : Routes.onboardingScreen,
          onGenerateRoute: appRouter.generateRoute,
        );
  },
),
      ),
    );
  }
}

Future<void> isLoggedIn() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final session = Supabase.instance.client.auth.currentSession;
  isLogin = session != null;
}
