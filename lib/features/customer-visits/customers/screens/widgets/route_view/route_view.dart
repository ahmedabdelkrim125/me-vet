import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/route_day_store.dart';
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
  final _store = RouteDayStore.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _init();
  }

  Future<void> _init() async {
    await _store.initialize();
    if (_store.stops.isEmpty) {
      await _seedDefaultRoute();
    }
    if (!mounted) return;
    _entranceController
      ..duration = Duration(milliseconds: 500 + _store.stops.length * 80)
      ..forward();
    setState(() => _ready = true);
  }

  Future<void> _seedDefaultRoute() async {
    final customers =
    MockCustomersRepository.instance.customers.take(3).toList();
    final stops = [
      for (int i = 0; i < customers.length; i++)
        RouteStopModel(
          customerId: customers[i].id,
          order: i + 1,
          customerName: customers[i].name,
          area: customers[i].area,
          status: RouteVisitStatus.pending,
        ),
    ];
    await _store.setStops(stops);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  RouteVisitStatus _previousStatusFor(String customerId) {
    final existing = _store.stops.where((s) => s.customerId == customerId);
    return existing.isEmpty ? RouteVisitStatus.pending : existing.first.status;
  }

  Future<void> _editRoute() async {
    final selectedIds = _store.stops.map((s) => s.customerId).toList();
    final selected = await showSelectRouteCustomersSheet(
      context,
      initiallySelectedIds: selectedIds,
    );
    if (selected == null) return;

    final stops = [
      for (int i = 0; i < selected.length; i++)
        RouteStopModel(
          customerId: selected[i].id,
          order: i + 1,
          customerName: selected[i].name,
          area: selected[i].area,
          status: _previousStatusFor(selected[i].id),
        ),
    ];
    await _store.setStops(stops);

    _entranceController
      ..duration = Duration(milliseconds: 500 + stops.length * 80)
      ..reset()
      ..forward();
    if (mounted) setState(() {});
  }

  Future<void> _addUnplannedVisit(CustomerModel customer) async {
    if (_store.stops.any((s) => s.customerId == customer.id)) return;
    final stops = List<RouteStopModel>.from(_store.stops)
      ..add(RouteStopModel(
        customerId: customer.id,
        order: _store.stops.length + 1,
        customerName: customer.name,
        area: customer.area,
        status: RouteVisitStatus.pending,
      ));
    await _store.setStops(stops);

    _entranceController
      ..duration = Duration(milliseconds: 500 + stops.length * 80)
      ..reset()
      ..forward();
    if (mounted) setState(() {});
  }

  Future<void> _reorderStops(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final stops = List<RouteStopModel>.from(_store.stops);
    final stop = stops.removeAt(oldIndex);
    stops.insert(newIndex, stop);
    for (var i = 0; i < stops.length; i++) {
      stops[i] = stops[i].copyWith(order: i + 1);
    }
    await _store.setStops(stops);
    if (mounted) setState(() {});
  }

  Future<void> _updateStatus(String customerId, RouteVisitStatus status) async {
    final index = _store.stops.indexWhere((s) => s.customerId == customerId);
    if (index == -1) return;
    await _store.updateStop(_store.stops[index].copyWith(status: status));
    if (mounted) setState(() {});
  }

  Future<void> _removeStop(String customerId) async {
    await _store.removeStop(customerId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<List<RouteStopModel>>(
      valueListenable: _store.stopsNotifier,
      builder: (context, stops, _) {
        final selectedCustomerIds = stops.map((s) => s.customerId).toList();
        final completed = stops
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
            RouteSummaryCard(total: stops.length, completed: completed),
            SizedBox(height: 14.h),
            UnplannedVisitButton(
              excludeIds: selectedCustomerIds,
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
              onReloadTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم إرسال طلب إعادة تحميل العربية')),
                );
              },
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