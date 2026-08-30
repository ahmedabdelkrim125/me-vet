// import 'package:flutter/material.dart';
// import '../../customer-visits/customers/screens/customers_screen.dart';
// import '../../daily_report/presentation/screens/daily_report_screen.dart';
// import '../../home/presentation/home_screen.dart';
// import '../../inventory/presentation/screens/inventory_screen.dart';
// import '../../settings/presentation/settings_screen.dart';
// import '../../vehicle_stock/presentation/screens/vehicle_stock_screen.dart';
// import 'widgets/app_bottom_nav_bar.dart';
// import 'widgets/app_side_menu_drawer.dart';
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
//       case 2:
//         return const InventoryScreen();
//       case 3:
//         return const VehicleStockScreen();
//       case 4:
//         return const DailyReportScreen();
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

//     return Scaffold(
//       drawer: AppSideMenuDrawer(
//         selectedIndex: _selectedIndex,
//         onTabChange: _onTabChange,
//       ),
//       body: Stack(
//         children: [
//           Positioned.fill(child: body),
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: AppBottomNavBar(
//               selectedIndex: _selectedIndex,
//               onTabChange: _onTabChange,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../customer-visits/customers/screens/customers_screen.dart';
import '../../daily_report/presentation/screens/daily_report_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../inventory/presentation/screens/inventory_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../vehicle_stock/presentation/screens/vehicle_stock_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/app_side_menu_drawer.dart';
import 'widgets/app_side_nav_bar.dart';
import 'widgets/detached_settings_button.dart';
import 'widgets/nav_items.dart';
import 'widgets/tab_placeholder.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _sideNavExpanded = true;

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CustomersScreen();
      case 2:
        return const InventoryScreen();
      case 3:
        return const VehicleStockScreen();
      case 4:
        return const DailyReportScreen();
      case 5:
        return const SettingsScreen();
      default:
        return TabPlaceholder(item: appNavItems[index]);
    }
  }

  Widget _animatedBody() {
    return AnimatedSwitcher(
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
  }

  @override
  Widget build(BuildContext context) {
    if (context.isTablet) return _buildTabletLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildTabletLayout(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: _sideNavExpanded ? 240.w : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 240.w,
                maxWidth: 240.w,
                alignment: Alignment.centerRight,
                child: AppSideNavBar(
                  selectedIndex: _selectedIndex,
                  onTabChange: _onTabChange,
                  onCollapse: () => setState(() => _sideNavExpanded = false),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _animatedBody()),
                if (!_sideNavExpanded)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: _CollapsedMenuButton(
                      onTap: () => setState(() => _sideNavExpanded = true),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final settingsIndex = appNavItems.length - 1;

    return Scaffold(
      drawer: AppSideMenuDrawer(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _animatedBody()),
          Positioned(
            left: 16.w,
            bottom: 76.h,
            child: DetachedSettingsButton(
              isSelected: _selectedIndex == settingsIndex,
              onTap: () => _onTabChange(settingsIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}

class _CollapsedMenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CollapsedMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(Icons.menu_rounded, color: colors.text, size: 22.sp),
        ),
      ),
    );
  }
}
