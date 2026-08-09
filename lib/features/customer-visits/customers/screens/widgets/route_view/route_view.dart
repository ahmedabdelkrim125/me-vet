import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import 'route_actions_bar.dart';
import 'route_report_sheet.dart';
import 'route_stop_tile.dart';
import 'route_summary_card.dart';
import 'route_visit_status_sheet.dart';
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
          customerId: customers[i].id,
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

  RouteVisitStatus _previousStatusFor(String customerId) {
    final existing = _stops.where((s) => s.customerId == customerId);
    return existing.isEmpty ? RouteVisitStatus.pending : existing.first.status;
  }

  void _renumber() {
    _stops = [
      for (int i = 0; i < _stops.length; i++) _stops[i].copyWith(order: i + 1),
    ];
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
            customerId: selected[i].id,
            order: i + 1,
            customerName: selected[i].name,
            area: selected[i].area,
            status: _previousStatusFor(selected[i].id),
          ),
      ];

      _entranceController
        ..duration = Duration(milliseconds: 500 + _stops.length * 80)
        ..reset()
        ..forward();
    });
  }

  void _addUnplannedVisit(CustomerModel customer) {
    if (_selectedCustomerIds.contains(customer.id)) return;
    setState(() {
      _selectedCustomerIds.add(customer.id);
      _stops.add(
        RouteStopModel(
          customerId: customer.id,
          order: _stops.length + 1,
          customerName: customer.name,
          area: customer.area,
          status: RouteVisitStatus.pending,
        ),
      );
      _entranceController
        ..duration = Duration(milliseconds: 500 + _stops.length * 80)
        ..reset()
        ..forward();
    });
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final stop = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, stop);
      _renumber();
    });
  }

  void _updateStatus(String customerId, RouteVisitStatus status) {
    setState(() {
      final index = _stops.indexWhere((s) => s.customerId == customerId);
      if (index == -1) return;
      _stops[index] = _stops[index].copyWith(status: status);
    });
  }

  void _removeStop(String customerId) {
    setState(() {
      _stops.removeWhere((s) => s.customerId == customerId);
      _selectedCustomerIds.remove(customerId);
      _renumber();
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
                    .copyWith(color: context.colors.text, fontSize: 15.sp),
              ),
            ),
            Material(
              color: context.colors.primary.withOpacity(0.1),
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
                          size: 14.sp, color: context.colors.primary),
                      SizedBox(width: 6.w),
                      Text(
                        'تعديل خط اليوم',
                        style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.primary, fontSize: 12.sp),
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
        UnplannedVisitButton(
          excludeIds: _selectedCustomerIds,
          onCustomerSelected: _addUnplannedVisit,
        ),
        SizedBox(height: 18.h),
        if (_stops.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Center(
              child: Text(
                'لسه محددتش عملاء لخط اليوم',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.textMuted, fontSize: 13.sp),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorderStops,
            itemCount: _stops.length,
            itemBuilder: (context, index) {
              final stop = _stops[index];
              return _AnimatedStopTile(
                key: ValueKey(stop.customerId),
                index: index,
                total: _stops.length,
                controller: _entranceController,
                stop: stop,
                isLast: index == _stops.length - 1,
                onTap: () => showRouteStopActionsSheet(
                  context,
                  stop: stop,
                  onStatusChanged: (status) =>
                      _updateStatus(stop.customerId, status),
                  onRemove: () => _removeStop(stop.customerId),
                ),
              );
            },
          ),
        SizedBox(height: 8.h),
        RouteActionsBar(
          onReportTap: () => showRouteReportSheet(context, _stops),
          onReloadTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال طلب إعادة تحميل العربية')),
            );
          },
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
  final VoidCallback onTap;

  const _AnimatedStopTile({
    super.key,
    required this.index,
    required this.total,
    required this.controller,
    required this.stop,
    required this.isLast,
    required this.onTap,
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
      child: RouteStopTile(
        stop: stop,
        isLast: isLast,
        index: index,
        onTap: onTap,
      ),
    );
  }
}
