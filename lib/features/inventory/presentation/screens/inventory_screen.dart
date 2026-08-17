import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/mock_inventory_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/vehicle_stock_model.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/add_to_vehicle_dialog.dart';
import '../widgets/inventory_category_filter.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/inventory_stat_row.dart';
import '../widgets/low_stock_alert_banner.dart';
import '../widgets/product_detail_sheet.dart';
import '../widgets/product_tile.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _query = '';
  ProductCategory? _category;

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

  List<ProductModel> _filter(List<ProductModel> products) {
    return products.where((p) {
      final matchesQuery = _query.isEmpty || p.name.contains(_query);
      final matchesCategory = _category == null || p.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();
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
              builder: (context, stockList, __) {
                return ValueListenableBuilder(
                  valueListenable: repo.alerts,
                  builder: (context, alerts, ___) {
                    final filtered = _filter(products);
                    final available = stockList
                        .where((s) => s.quantity > s.minThreshold)
                        .length;
                    final low = stockList
                        .where((s) =>
                            s.quantity > 0 && s.quantity <= s.minThreshold)
                        .length;
                    final outOfStock =
                        stockList.where((s) => s.quantity == 0).length;

                    return Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                          children: [
                            InventoryStatRow(
                              total: products.length,
                              available: available,
                              low: low,
                              outOfStock: outOfStock,
                            ),
                            SizedBox(height: 14.h),
                            LowStockAlertBanner(alerts: alerts),
                            if (alerts.isNotEmpty) SizedBox(height: 14.h),
                            InventorySearchBar(
                                onChanged: (v) => setState(() => _query = v)),
                            SizedBox(height: 12.h),
                            InventoryCategoryFilter(
                              selected: _category,
                              onChanged: (c) => setState(() => _category = c),
                            ),
                            SizedBox(height: 14.h),
                            for (int i = 0; i < filtered.length; i++)
                              _AnimatedProductTile(
                                index: i,
                                total: filtered.length,
                                controller: _controller,
                                product: filtered[i],
                                stock: repo.stockOf(filtered[i].id),
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
                              onTap: () => showAddProductSheet(context),
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                child: Text(
                                  'إضافة صنف جديد',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: Colors.white, fontSize: 13.sp),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}

class _AnimatedProductTile extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final ProductModel product;
  final VehicleStockModel? stock;

  const _AnimatedProductTile({
    required this.index,
    required this.total,
    required this.controller,
    required this.product,
    required this.stock,
  });

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
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - animation.value)), child: child),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: ProductTile(
          product: product,
          stock: stock,
          onTap: () => showProductDetailSheet(context, product),
         onAddToVehicle: () {
  showAddToVehicleDialog(
    context,
    product: product,
    onConfirm: (quantity, threshold) => MockInventoryRepository.instance.loadToVehicle(
      productId: product.id,
      quantity: quantity,
      minThreshold: threshold,
    ),
  );
},
        ),
      ),
    );
  }
}
