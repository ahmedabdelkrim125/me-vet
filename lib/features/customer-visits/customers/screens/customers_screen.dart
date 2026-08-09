import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'widgets/customers_list_view/customers_list_view.dart';
import 'widgets/route_view/route_view.dart';
import 'widgets/shared/customers_sub_view_switcher.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  int _subViewIndex = 0;
  bool _movingForward = true;

  void _onSubViewChanged(int index) {
    if (index == _subViewIndex) return;
    setState(() {
      _movingForward = index > _subViewIndex;
      _subViewIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: CustomersSubViewSwitcher(
                selectedIndex: _subViewIndex,
                onChanged: _onSubViewChanged,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offsetX = _movingForward ? 0.08 : -0.08;
                  final slide = Tween<Offset>(
                    begin: Offset(offsetX, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _subViewIndex == 0
                    ? const RouteView(key: ValueKey('route'))
                    : const CustomersListView(key: ValueKey('list')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
