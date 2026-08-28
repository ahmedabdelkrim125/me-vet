import 'package:flutter/material.dart';
import '../../customer-visits/customers/screens/customers_screen.dart';
import '../../daily_report/presentation/screens/daily_report_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../inventory/presentation/screens/inventory_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../vehicle_stock/presentation/screens/vehicle_stock_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/app_side_menu_drawer.dart';
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

    // ملحوظة مهمة: مكنتش حاطط AppBottomNavBar في bottomNavigationBar
    // slot بتاع الـ Scaffold — ده اتضح إنه سبب المشكلة. فيه باگ موثّق في
    // Flutter نفسه (github.com/flutter/flutter/issues/162006 وغيره):
    // BackdropFilter جوّا bottomNavigationBar تحديدًا بيتعارض مع محرك
    // الرندر الجديد Impeller (الافتراضي دلوقتي) والـ blur ميبانش صح.
    // الحل الموثّق: تحط الـ glass widget كـ layer عائم فوق الـ body
    // (Stack + Positioned) بدل الـ slot المخصص — وده اللي عملناه هنا.
    return Scaffold(
      drawer: AppSideMenuDrawer(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
            ),
          ),
        ],
      ),
    );
  }
}
