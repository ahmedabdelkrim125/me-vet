import 'package:flutter/material.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/rep_session/presentation/rep_entry_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.repEntryScreen:
        return MaterialPageRoute(builder: (_) => const RepEntryScreen());
      case Routes.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      // case Routes.onBoardingScreen:
      //   return MaterialPageRoute(builder: (_) => const OnBoardingScreen());
      // case Routes.loginScreen:
      //   return MaterialPageRoute(builder: (_) => const LoginScreen());
      // case Routes.signupScreen:
      //   return MaterialPageRoute(builder: (_) => const SignupScreen());
      // case Routes.verificationScreen:
      //   return MaterialPageRoute(builder: (_) => const VerificationScreen());
      // case Routes.forgotPasswordScreen:
      //   return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      // case Routes.resetPasswordScreen:
      //   return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      // case Routes.homeScreen:
      //   return MaterialPageRoute(builder: (_) => const HomeScreen());
      // case Routes.categoriesDetailsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const CategoriesDetailsScreen(),
      //   );
      // case Routes.categoryBooksScreen:
      //   final title = settings.arguments as String? ?? '';
      //   return MaterialPageRoute(
      //     builder: (_) => CategoryBooksScreen(categoryTitle: title),
      //   );
      // case Routes.addBookScreen:
      //   final bookToEdit = settings.arguments as MyBookModel?;
      //   return MaterialPageRoute(
      //     builder: (_) => AddBookScreen(bookToEdit: bookToEdit),
      //   );
      // case Routes.bookDetailsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const BookDetailsScreen(),
      //   );
      // case Routes.chatDetailsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const ChatDetailsScreen(),
      //   );
      // case Routes.accountScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const AccountScreen(),
      //   );
      // case Routes.myAccountScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const MyAccountScreen(),
      //   );
      // case Routes.myBooksScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const MyBookScreen(),
      //   );
      // case Routes.activitiesScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const ActivitiesScreen(),
      //   );
      // case Routes.settingsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const SettingsScreen(),
      //   );
      // case Routes.ratingsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const RatingsScreen(),
      //   );
      // case Routes.deleteAccountScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const DeleteAccountScreen(),
      //   );
      // case Routes.aboutAppScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const AboutAppScreen(),
      //   );
      // case Routes.notificationsScreen:
      //   return MaterialPageRoute(
      //     builder: (_) => const NotificationsScreen(),
      //   );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
