import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import 'route_actions_bar.dart';
import 'route_report_sheet.dart';
import 'route_stop_tile.dart';
import 'route_summary_card.dart';
import 'select_route_customers_sheet.dart';
import 'unplanned_visit_button.dart';

class RouteView extends StatefulWidget {
  const RouteView({super.key});

  @override
  State<RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<RouteView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  List<RouteStopModel> _stops = [];
  final List<String> _selectedCustomerIds = [];

  @override
  void initState() {
    super.initState();
    _buildInitialRoute();
    _entranceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 + _stops.length * 80),
    )..forward();
  }

  void _buildInitialRoute() {
    final customers =
        MockCustomersRepository.instance.customers.take(3).toList();
    _selectedCustomerIds.addAll(customers.map((c) => c.id));
    _stops = [
      for (int i = 0; i < customers.length; i++)
        RouteStopModel(
          order: i + 1,
          customerName: customers[i].name,
          area: customers[i].area,
          status: RouteVisitStatus.pending,
        ),
    ];
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  RouteVisitStatus _previousStatusFor(String customerName) {
    final existing = _stops.where((s) => s.customerName == customerName);
    return existing.isEmpty ? RouteVisitStatus.pending : existing.first.status;
  }

  Future<void> _editRoute() async {
    final selected = await showSelectRouteCustomersSheet(
      context,
      initiallySelectedIds: _selectedCustomerIds,
    );
    if (selected == null) return;

    setState(() {
      _selectedCustomerIds
        ..clear()
        ..addAll(selected.map((c) => c.id));

      _stops = [
        for (int i = 0; i < selected.length; i++)
          RouteStopModel(
            order: i + 1,
            customerName: selected[i].name,
            area: selected[i].area,
            status: _previousStatusFor(selected[i].name),
          ),
      ];

      _entranceController
        ..duration = Duration(milliseconds: 500 + _stops.length * 80)
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _stops
        .where((s) =>
            s.status == RouteVisitStatus.completed ||
            s.status == RouteVisitStatus.sold)
        .length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'خط اليوم',
                style: AppTextStyles.cairoBold18
                    .copyWith(color: AppColors.primary, fontSize: 15.sp),
              ),
            ),
            Material(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: _editRoute,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.pencil,
                          size: 14.sp, color: AppColors.primaryGreen),
                      SizedBox(width: 6.w),
                      Text(
                        'تعديل خط اليوم',
                        style: AppTextStyles.cairoMedium16.copyWith(
                            color: AppColors.primaryGreen, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        RouteSummaryCard(total: _stops.length, completed: completed),
        SizedBox(height: 14.h),
        const UnplannedVisitButton(),
        SizedBox(height: 18.h),
        if (_stops.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Center(
              child: Text(
                'لسه محددتش عملاء لخط اليوم',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: AppColors.navInactive, fontSize: 13.sp),
              ),
            ),
          )
        else
          for (int i = 0; i < _stops.length; i++)
            _AnimatedStopTile(
              index: i,
              total: _stops.length,
              controller: _entranceController,
              stop: _stops[i],
              isLast: i == _stops.length - 1,
            ),
        SizedBox(height: 8.h),
        RouteActionsBar(
          onReportTap: () => showRouteReportSheet(context, _stops),
          onReloadTap: () {},
        ),
      ],
    );
  }
}

class _AnimatedStopTile extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final RouteStopModel stop;
  final bool isLast;

  const _AnimatedStopTile({
    required this.index,
    required this.total,
    required this.controller,
    required this.stop,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final start = (index / safeTotal) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: RouteStopTile(stop: stop, isLast: isLast),
    );
  }
}
