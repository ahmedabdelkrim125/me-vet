import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../customer-visits/customers/screens/customers_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/app_side_nav_bar.dart';
import 'widgets/nav_items.dart';
import 'widgets/tab_placeholder.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onNavigateToCustomers: () => _onTabChange(1),);
      case 1:
        return const CustomersScreen();
      case 5:
        return const SettingsScreen();
      default:
        return TabPlaceholder(item: appNavItems[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_selectedIndex),
        child: _buildPage(_selectedIndex),
      ),
    );

    if (context.isTablet || context.isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            AppSideNavBar(
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../customer-visits/customers/screens/customers_screen.dart';
// import '../../home/presentation/home_screen.dart';
// import '../../settings/presentation/settings_screen.dart';
// import 'widgets/app_bottom_nav_bar.dart';
// import 'widgets/app_side_nav_bar.dart';
// import 'widgets/nav_items.dart';
// import 'widgets/tab_placeholder.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int _selectedIndex = 0;

//   void _onTabChange(int index) {
//     setState(() => _selectedIndex = index);
//   }

//   Widget _buildPage(int index) {
//     switch (index) {
//       case 0:
//         return const HomeScreen();
//       case 1:
//         return const CustomersScreen();
//       case 5:
//         return const SettingsScreen();
//       default:
//         return TabPlaceholder(item: appNavItems[index]);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final body = AnimatedSwitcher(
//       duration: const Duration(milliseconds: 350),
//       switchInCurve: Curves.easeOut,
//       switchOutCurve: Curves.easeIn,
//       transitionBuilder: (child, animation) {
//         final slide = Tween<Offset>(
//           begin: const Offset(0, 0.03),
//           end: Offset.zero,
//         ).animate(animation);

//         return FadeTransition(
//           opacity: animation,
//           child: SlideTransition(position: slide, child: child),
//         );
//       },
//       child: KeyedSubtree(
//         key: ValueKey(_selectedIndex),
//         child: _buildPage(_selectedIndex),
//       ),
//     );

//     if (context.isTablet || context.isDesktop) {
//       return Scaffold(
//         body: Row(
//           children: [
//             AppSideNavBar(
//               selectedIndex: _selectedIndex,
//               onTabChange: _onTabChange,
//             ),
//             Expanded(child: body),
//           ],
//         ),
//       );
//     }

//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(child: body),
//           AppBottomNavBar(
//             selectedIndex: _selectedIndex,
//             onTabChange: _onTabChange,
//           ),
//         ],
//       ),
//     );
//   }
// }
