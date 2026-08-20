import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/mock_inventory_repository.dart';
import '../../../inventory/domain/models/main_warehouse_stock_model.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../inventory/domain/models/stock_alert_model.dart';
import '../../../inventory/domain/models/stock_movement_model.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';
import '../../../inventory/presentation/widgets/add_to_vehicle_dialog.dart';
import '../../../inventory/presentation/widgets/inventory_search_bar.dart';
import '../../../inventory/presentation/widgets/inventory_stat_row.dart';
import '../../../inventory/presentation/widgets/low_stock_alert_banner.dart';
import '../widgets/add_to_warehouse_dialog.dart';
import '../widgets/request_reload_sheet.dart';
import '../widgets/stock_movement_log_sheet.dart';
import '../widgets/vehicle_stock_sub_view_switcher.dart';
import '../widgets/vehicle_stock_tile.dart';
import '../widgets/warehouse_stock_tile.dart';

class VehicleStockScreen extends StatefulWidget {
  const VehicleStockScreen({super.key});

  @override
  State<VehicleStockScreen> createState() => _VehicleStockScreenState();
}

class _VehicleStockScreenState extends State<VehicleStockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _subViewIndex = 0;
  bool _movingForward = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    MockInventoryRepository.instance.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubViewChanged(int index) {
    if (index == _subViewIndex) return;
    setState(() {
      _movingForward = index > _subViewIndex;
      _subViewIndex = index;
      _controller
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockInventoryRepository.instance;

    return Container(
      color: context.colors.background,
      child: SafeArea(
        child: ValueListenableBuilder<List<ProductModel>>(
          valueListenable: repo.products,
          builder: (context, products, _) {
            return ValueListenableBuilder<List<VehicleStockModel>>(
              valueListenable: repo.vehicleStock,
              builder: (context, vehicleStock, __) {
                return ValueListenableBuilder<List<MainWarehouseStockModel>>(
                  valueListenable: repo.mainWarehouseStock,
                  builder: (context, warehouseStock, ___) {
                    return ValueListenableBuilder<List<StockAlertModel>>(
                      valueListenable: repo.alerts,
                      builder: (context, alerts, ____) {
                        return ValueListenableBuilder<List<StockMovementModel>>(
                          valueListenable: repo.movements,
                          builder: (context, movements, _____) {
                            return _buildBody(
                              context,
                              vehicleStock: vehicleStock,
                              warehouseStock: warehouseStock,
                              alerts: alerts,
                              movements: movements,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<VehicleStockModel> vehicleStock,
    required List<MainWarehouseStockModel> warehouseStock,
    required List<StockAlertModel> alerts,
    required List<StockMovementModel> movements,
  }) {
    final isWarehouseView = _subViewIndex == 0;
    final repo = MockInventoryRepository.instance;

    final warehouseEntries = warehouseStock.where((s) {
      final product = repo.productById(s.productId);
      if (product == null) return false;
      return _query.isEmpty || product.name.contains(_query);
    }).toList();

    final vehicleEntries = vehicleStock.where((s) {
      final product = repo.productById(s.productId);
      if (product == null) return false;
      return _query.isEmpty || product.name.contains(_query);
    }).toList();

    final totalItems =
        isWarehouseView ? warehouseStock.length : vehicleStock.length;
    final available = isWarehouseView
        ? warehouseStock.where((s) {
            final product = repo.productById(s.productId);
            return product != null && s.quantity > product.minStockThreshold;
          }).length
        : vehicleStock.where((s) => s.quantity > s.minThreshold).length;
    final low = isWarehouseView
        ? warehouseStock.where((s) {
            final product = repo.productById(s.productId);
            return product != null &&
                s.quantity > 0 &&
                s.quantity <= product.minStockThreshold;
          }).length
        : vehicleStock
            .where((s) => s.quantity > 0 && s.quantity <= s.minThreshold)
            .length;
    final outOfStock = isWarehouseView
        ? warehouseStock.where((s) => s.quantity == 0).length
        : vehicleStock.where((s) => s.quantity == 0).length;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: VehicleStockSubViewSwitcher(
                    selectedIndex: _subViewIndex,
                    onChanged: _onSubViewChanged,
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => showStockMovementLogSheet(context, movements),
                    child: Container(
                      width: 52.h,
                      height: 52.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Icon(Icons.history_rounded,
                          color: context.colors.primary, size: 20.sp),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            InventoryStatRow(
                total: totalItems,
                available: available,
                low: low,
                outOfStock: outOfStock),
            SizedBox(height: 14.h),
            LowStockAlertBanner(alerts: alerts),
            if (alerts.isNotEmpty) SizedBox(height: 14.h),
            InventorySearchBar(onChanged: (v) => setState(() => _query = v)),
            SizedBox(height: 14.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetX = _movingForward ? 0.06 : -0.06;
                final slide =
                    Tween<Offset>(begin: Offset(offsetX, 0), end: Offset.zero)
                        .animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                );
                return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child));
              },
              child: isWarehouseView
                  ? _WarehouseList(
                      key: const ValueKey('warehouse'),
                      entries: warehouseEntries,
                      controller: _controller,
                    )
                  : _VehicleList(
                      key: const ValueKey('vehicle'),
                      entries: vehicleEntries,
                      controller: _controller,
                    ),
            ),
          ],
        ),
        Positioned(
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
          child: Material(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(16.r),
            elevation: 6,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () =>
                  showRequestReloadSheet(context, alerts: List.from(alerts)),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Text(
                  'طلب إعادة تحميل العربية',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: Colors.white, fontSize: 13.sp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarehouseList extends StatelessWidget {
  final List<MainWarehouseStockModel> entries;
  final AnimationController controller;

  const _WarehouseList(
      {super.key, required this.entries, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: Center(
          child: Text(
            'المخزن الرئيسي فاضي دلوقتي',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: context.colors.textMuted, fontSize: 13.sp),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _AnimatedTile(
            index: i,
            total: entries.length,
            controller: controller,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: WarehouseStockTile(
                product: MockInventoryRepository.instance
                    .productById(entries[i].productId)!,
                stock: entries[i],
                onAdd: () => showAddToWarehouseDialog(
                  context,
                  product: MockInventoryRepository.instance
                      .productById(entries[i].productId)!,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VehicleList extends StatelessWidget {
  final List<VehicleStockModel> entries;
  final AnimationController controller;

  const _VehicleList(
      {super.key, required this.entries, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: Center(
          child: Text(
            'لسه مفيش أصناف محملة في العربية',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: context.colors.textMuted, fontSize: 13.sp),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _AnimatedTile(
            index: i,
            total: entries.length,
            controller: controller,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: VehicleStockTile(
                product: MockInventoryRepository.instance
                    .productById(entries[i].productId)!,
                stock: entries[i],
                onLoadMore: () => showAddToVehicleDialog(
                  context,
                  product: MockInventoryRepository.instance
                      .productById(entries[i].productId)!,
                  onConfirm: (quantity, threshold) =>
                      MockInventoryRepository.instance.loadToVehicle(
                    productId: entries[i].productId,
                    quantity: quantity,
                    minThreshold: threshold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final Widget child;

  const _AnimatedTile(
      {required this.index,
      required this.total,
      required this.controller,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final start = (index / safeTotal) * 0.5;
    final end = (start + 0.5).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - animation.value)), child: child),
        );
      },
      child: child,
    );
  }
}
