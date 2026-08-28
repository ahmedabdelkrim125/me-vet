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

    // نفس التصميم بالظبط على أي مقاس شاشة (فون/تابلت/ديسكتوب) — من قبل
    // كان فيه نسخة تانية منفصلة (AppSideNavBar) للشاشات العريضة، وده اللي
    // سبب لخبطة إن التعديلات بتتطبق على واحد بس من الاتنين. دلوقتي واجهة
    // واحدة بس، الناف بار السفلي + المنيو الجانبي (بيفتح من شعار التطبيق
    // في هيدر الرئيسية) شغالين لأي حد بيفتح التطبيق.
    return Scaffold(
      // extendBody: true عشان محتوى الشاشة يمتد فعليًا تحت الناف بار،
      // وده اللي بيخلي تأثير الزجاج (الـ blur) يبين فعليًا — من غيرها
      // مفيش حاجة وراه يعكسها فيبان شكل عادي فاضي. كل شاشة من الـ 6
      // فيها مسافة إضافية (SizedBox) في آخر المحتوى القابل للتمرير
      // عشان آخر حاجة فيها متتغطاش — هراجعها واحدة واحدة مع باقي فيتشرات
      // الـ Dark Mode.
      extendBody: true,
      drawer: AppSideMenuDrawer(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
      body: body,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}
