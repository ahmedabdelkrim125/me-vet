import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_type_screen.dart';
import '../../features/auth/presentation/screens/owner_login_screen.dart';
import '../../features/auth/presentation/screens/rep_login_screen.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/owner_dashboard/presentation/owner_dashboard_screen.dart';
import '../../features/rep_session/presentation/rep_entry_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.loginTypeScreen:
        return MaterialPageRoute(builder: (_) => const LoginTypeScreen());
      case Routes.ownerLoginScreen:
        return MaterialPageRoute(builder: (_) => const OwnerLoginScreen());
      case Routes.repLoginScreen:
        return MaterialPageRoute(builder: (_) => const RepLoginScreen());
      case Routes.ownerDashboard:
        return MaterialPageRoute(builder: (_) => const OwnerDashboardScreen());
      case Routes.repEntryScreen:
        return MaterialPageRoute(builder: (_) => const RepEntryScreen());
      case Routes.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
