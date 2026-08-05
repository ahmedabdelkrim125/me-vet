import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
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

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _selectedIndex,
      children: appNavItems.map((item) => TabPlaceholder(item: item)).toList(),
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
