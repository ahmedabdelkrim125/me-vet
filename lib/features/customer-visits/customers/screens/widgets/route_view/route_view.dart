import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/route_stop_model.dart';
import '../../../domain/models/visit_status.dart';
import '../../../domain/today_route_controller.dart';
import 'route_actions_bar.dart';
import 'route_incomplete_customers_sheet.dart';
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

  final TodayRouteController _routeController = TodayRouteController.instance;
  bool _showedNewDayDecision = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: 500 + _routeController.stops.length * 80),
    )..forward();
    _routeController.stopsNotifier.addListener(_restartEntranceAnimation);
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    await _routeController.initialize();
    if (!mounted || !_routeController.shouldAskForNewDayDecision) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showedNewDayDecision) return;
      _showedNewDayDecision = true;
      _showNewDayDecisionDialog();
    });
  }

  void _restartEntranceAnimation() {
    _entranceController
      ..duration = Duration(
        milliseconds: 500 + _routeController.stops.length * 80,
      )
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _routeController.stopsNotifier.removeListener(_restartEntranceAnimation);
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _editRoute() async {
    await _routeController.initialize();
    if (!mounted) return;

    final selected = await showSelectRouteCustomersSheet(
      context,
      initiallySelectedIds: _routeController.selectedCustomerIds,
    );
    if (selected == null) return;

    await _routeController.setSelectedCustomers(selected);
  }

  void _addUnplannedVisit(CustomerModel customer) =>
      _routeController.addCustomer(customer);

  void _reorderStops(int oldIndex, int newIndex) {
    _routeController.reorderStops(oldIndex, newIndex);
  }

  void _updateStatus(String customerId, RouteVisitStatus status) {
    _routeController.updateStatus(customerId, status);
  }

  void _removeStop(String customerId) {
    _routeController.removeStop(customerId);
  }

  Future<void> _carryIncompleteToDay(DateTime targetDay) async {
    final count = _routeController.incompleteStops.length;
    await _routeController.carryIncompleteToDay(targetDay);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم ترحيل $count عميل')),
    );
  }

  Future<void> _showIncompleteCustomers() async {
    await showIncompleteRouteCustomersSheet(
      context,
      stops: _routeController.incompleteStops,
      onCarryToDay: _carryIncompleteToDay,
    );
  }

  Future<void> _showNewDayDecisionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('خط اليوم قديم'),
          content: const Text(
            'مر أكتر من 24 ساعة على خط اليوم. تحب ترحل العملاء غير المكتملين لليوم الجديد ولا تمسح الخط وتبدأ من جديد؟',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _routeController.clearTodayRoute();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('مسح وبدء جديد'),
            ),
            FilledButton(
              onPressed: () async {
                await _routeController.carryIncompleteToNewDay();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('ترحيل المتبقي'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RouteStopModel>>(
      valueListenable: _routeController.stopsNotifier,
      builder: (context, stops, _) {
        final completed = _routeController.completedVisits;

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
            RouteSummaryCard(total: stops.length, completed: completed),
            SizedBox(height: 14.h),
            UnplannedVisitButton(
              excludeIds: _routeController.selectedCustomerIds,
              onCustomerSelected: _addUnplannedVisit,
            ),
            SizedBox(height: 18.h),
            if (stops.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: Center(
                  child: Text(
                    'لسه محددتش عملاء لخط اليوم',
                    style: AppTextStyles.cairoMedium16.copyWith(
                        color: context.colors.textMuted, fontSize: 13.sp),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _reorderStops,
                itemCount: stops.length,
                itemBuilder: (context, index) {
                  final stop = stops[index];
                  return _AnimatedStopTile(
                    key: ValueKey(stop.customerId),
                    index: index,
                    total: stops.length,
                    controller: _entranceController,
                    stop: stop,
                    isLast: index == stops.length - 1,
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
              onReportTap: () => showRouteReportSheet(context, stops),
              onIncompleteTap: _showIncompleteCustomers,
            ),
          ],
        );
      },
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
