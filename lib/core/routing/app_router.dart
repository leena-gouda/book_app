
import 'package:book_app/core/routing/routes.dart';
import 'package:book_app/features/Reviews/ui/screens/user_review_screen.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/ebook_access_dialog.dart';
import 'package:book_app/features/bookDetails/ui/screens/widgets/ebook_reader_screen.dart';
import 'package:book_app/features/dashboard/ui/screens/dashboard_screen.dart';
import 'package:book_app/features/home/data/models/book_model.dart';
import 'package:book_app/features/bookDetails/ui/screens/book_details.dart';
import 'package:book_app/features/home/ui/screens/widgets/see_all_screen.dart';
import 'package:book_app/features/myLibrary/ui/screens/my_library.dart';
import 'package:book_app/features/profile/ui/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../features/Reviews/ui/screens/reviews_screen.dart';
import '../../features/auth/login/ui/screens/login_screen.dart';
import '../../features/auth/signup/ui/screens/sign_up_screen.dart';
import '../../features/home/ui/screens/home_screen.dart';
import '../../features/onboarding/ui/screens/onboarding.dart';
import '../../features/searchScreen/ui/screens/search_screen.dart';
import '../../features/splash_screen/ui/views/splash_screen.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    switch (settings.name) {
      case Routes.splashScreen:
        return _createRoute(SplashScreen());
      case Routes.onboardingScreen:
        return _createRoute(OnboardingScreen());
      case Routes.homeScreen:
        return _createRoute(HomeScreen());
      case Routes.loginScreen:
        return _createRoute(LoginScreen());
      case Routes.signupsScreen:
        return _createRoute(SignUpScreen());
      case Routes.bookDetailsScreen:
        final args = arguments as Map<String, dynamic>;
        final books = args['books'] as Items;
        final progress = args['progress'] as double?;
        return _createRoute(BookDetails(book: books,progress: progress,));
      case Routes.reviewsScreen:
        final args = arguments as Map<String, dynamic>;
        final bookId = args['bookId'] as String;
        final reviews = args['reviews'] as List<Map<String, dynamic>>;
        return _createRoute(AllReviewsPage(bookId: bookId, reviews: reviews));
      case Routes.myLibraryScreen:
        return _createRoute(MyLibrary());
      case Routes.seeAllScreen:
        final args = arguments as Map<String, dynamic>;
        final title = args['title'] as String;
        final items = args['items'] as List<Items>;
        final filterText = args['filterText'] as String;
        return _createRoute(SeeAllScreen(title: title, items: items, filterText: filterText,));
      case Routes.searchScreen:
        final args = arguments as Map<String, dynamic>?;
        final allBooks = args != null && args['allBooks'] is List<Items> ? args['allBooks'] as List<Items> : <Items>[];
        return _createRoute(SearchScreen(allBooks: allBooks,));
      case Routes.dashboardScreen:
        final args = arguments as Map<String, dynamic>;
        final userId = args['userId'] as String;
        return _createRoute(DashboardScreen(userId: userId)); // Placeholder
      case Routes.ebookReaderScreen:
        final args = arguments as Map<String, dynamic>;
        final bookTitle = args['bookTitle'] as String;
        final ebookUrl = args['ebookUrl'] as String;
        final bookId = args['bookId'] as String;
        final bookContent = args['bookContent'] as Map<String, dynamic>;
        return   _createRoute(EBookReaderScreen( bookTitle: bookTitle, bookContent: bookContent,));
      case Routes.profileScreen:
        return _createRoute(ProfileScreen());
      case Routes.userReviewScreen:
        return _createRoute(UserReviewsScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  PageRouteBuilder _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}