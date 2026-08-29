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

  // بنقيس ارتفاع الناف بار فعليًا بعد ما يترسم (مش رقم ثابت بنخمّنه) —
  // عشان أي تعديل مستقبلي في تصميمه (ارتفاع، padding، حجم خط) ينعكس هنا
  // أوتوماتيك من غير ما حد يحتاج يفتكر يظبط رقم في مكان تاني.
  final GlobalKey _navBarKey = GlobalKey();
  double _navBarHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNavBar());
  }

  void _measureNavBar() {
    final renderBox =
        _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    final height = renderBox?.size.height ?? 0;
    if (height > 0 && height != _navBarHeight && mounted) {
      setState(() => _navBarHeight = height);
    }
  }

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
    // الناف بار ممكن يتغيّر ارتفاعه شكليًا (تكبير التاب المختار مثلًا)،
    // فبنعيد القياس بعد أي تبديل تاب للتأكد.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNavBar());
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

    // كل الشاشات الـ 6 ملفوفة في SafeArea أصلًا — فبدل ما كل شاشة تضيف
    // مسافة فاضية يدوية تحاول تخمّن ارتفاع الناف بار، بنضخّم الـ
    // MediaQuery.padding.bottom اللي كل SafeArea بتقرا منها بقيمة
    // الارتفاع الحقيقي المقاس. الحل بقى في مكان واحد بس، مش متكرر.
    final inflatedMediaQuery = MediaQuery.of(context).copyWith(
      padding: MediaQuery.of(context).padding.copyWith(
            bottom: _navBarHeight,
          ),
    );

    return Scaffold(
      drawer: AppSideMenuDrawer(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: inflatedMediaQuery,
              child: body,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeyedSubtree(
              key: _navBarKey,
              child: AppBottomNavBar(
                selectedIndex: _selectedIndex,
                onTabChange: _onTabChange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
