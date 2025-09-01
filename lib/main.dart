import 'package:book_app/core/network/dio_client.dart';
import 'package:book_app/features/Reviews/data/repo/review_repo.dart';
import 'package:book_app/features/Reviews/ui/cubit/review_cubit.dart';
import 'package:book_app/features/auth/login/ui/cubit/login_cubit.dart';
import 'package:book_app/features/auth/signup/ui/cubit/signup_cubit.dart';
import 'package:book_app/features/home/data/repos/book_api_repo.dart';
import 'package:book_app/features/home/data/repos/mockrepo.dart';
import 'package:book_app/features/home/data/repos/nyt_books_repo.dart';
import 'package:book_app/features/home/ui/cubit/home_cubit.dart';
import 'package:book_app/features/home/ui/screens/home_screen.dart';
import 'package:book_app/features/myLibrary/data/repos/library_repo.dart';
import 'package:book_app/features/myLibrary/ui/cubit/button_cubit.dart';
import 'package:book_app/features/myLibrary/ui/cubit/my_library_cubit.dart';
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

bool isLogin = false;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {


    const supabaseUrl = 'https://xfgxabuovlviqjixipib.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmZ3hhYnVvdmx2aXFqaXhpcGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMTkyOTksImV4cCI6MjA3MTg5NTI5OX0.-FrH7aiXIDuvxwY69kaxHHZ2OeTKaDDyt5kjrTprnsw'; // your actual anon key

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    Bloc.observer = AppBlocObserver();

    await isLoggedIn();

    runApp(MyApp(appRouter: AppRouter()));
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
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.0,
            ),
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          initialRoute: isLogin ? Routes.homeScreen : Routes.splashScreen,
          onGenerateRoute: appRouter.generateRoute,
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
