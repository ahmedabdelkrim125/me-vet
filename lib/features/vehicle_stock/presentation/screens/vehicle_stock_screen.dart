import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/add_to_vehicle_dialog.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/inventory_search_bar.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/inventory_stat_row.dart';
import '../widgets/vehicle_stock_tile.dart';
import '../widgets/stock_movement_log_sheet.dart';

class VehicleStockScreen extends StatelessWidget {
  const VehicleStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VehicleStockCubit>()..loadVehicles(),
      child: const _VehicleStockView(),
    );
  }
}

class _VehicleStockView extends StatefulWidget {
  const _VehicleStockView();

  @override
  State<_VehicleStockView> createState() => _VehicleStockViewState();
}

class _VehicleStockViewState extends State<_VehicleStockView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<VehicleStockCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      child: SafeArea(
        child: BlocConsumer<VehicleStockCubit, VehicleStockState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!)),
              );
              context.read<VehicleStockCubit>().clearMessages();
            }

            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
              context.read<VehicleStockCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            if (state.status == VehicleStockStatus.initial ||
                state.status == VehicleStockStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.vehicles.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 52.sp,
                      color: context.colors.textMuted,
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Text(
                        'لا توجد عربيات مرتبطة بهذا الحساب',
                        style: AppTextStyles.cairoMedium16.copyWith(
                          color: context.colors.textMuted,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final selectedVehicle = state.selectedVehicle;
            if (selectedVehicle == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = state.vehicleStock.where((entry) {
              final product = entry.product;
              if (product == null) return false;
              return _query.isEmpty ||
                  product.name.toLowerCase().contains(_query.toLowerCase());
            }).toList();

            final total = state.vehicleStock.length;
            final available = state.vehicleStock
                .where((item) => item.quantity > item.minThreshold)
                .length;
            final low = state.vehicleStock
                .where((item) =>
                    item.quantity > 0 && item.quantity <= item.minThreshold)
                .length;
            final outOfStock =
                state.vehicleStock.where((item) => item.quantity == 0).length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: context.colors.border,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedVehicle.id,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: context.colors.textMuted,
                              ),
                              dropdownColor: context.colors.surface,
                              items: state.vehicles
                                  .map(
                                    (vehicle) => DropdownMenuItem<String>(
                                      value: vehicle.id,
                                      child: Text(
                                        '${vehicle.plateNumber} — ${vehicle.driverName}',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.cairoMedium16
                                            .copyWith(
                                          color: context.colors.text,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (vehicleId) {
                                if (vehicleId != null) {
                                  context
                                      .read<VehicleStockCubit>()
                                      .selectVehicle(vehicleId);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Material(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => showStockMovementLogSheet(
                            context,
                            state.movements,
                          ),
                          child: Container(
                            width: 52.h,
                            height: 52.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: context.colors.border,
                              ),
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: context.colors.primary,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  InventoryStatRow(
                    total: total,
                    available: available,
                    low: low,
                    outOfStock: outOfStock,
                  ),
                  SizedBox(height: 14.h),
                  InventorySearchBar(
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                  ),
                  SizedBox(height: 14.h),
                  if (state.status == VehicleStockStatus.loadingStock)
                    const LinearProgressIndicator(),
                  SizedBox(height: 8.h),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 60.h),
                      child: Center(
                        child: Text(
                          state.vehicleStock.isEmpty
                              ? 'لسه مفيش أصناف محملة في العربية'
                              : 'لا توجد أصناف مطابقة للبحث',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.textMuted,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < filtered.length; i++)
                      _AnimatedVehicleTile(
                        index: i,
                        total: filtered.length,
                        controller: _controller,
                        stock: filtered[i],
                        onLoadMore: () => _loadMore(
                          context,
                          selectedVehicle.id,
                          filtered[i],
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadMore(
    BuildContext context,
    String vehicleId,
    VehicleStockModel stock,
  ) async {
    final product = stock.product;
    if (product == null) return;

    await showAddToVehicleDialog(
      context,
      product: product,
      onConfirm: (quantity, minThreshold) async {
        try {
          await context.read<VehicleStockCubit>().loadStock(
                vehicleId: vehicleId,
                productId: product.id,
                quantity: quantity,
                minThreshold: minThreshold,
              );
          return null;
        } catch (e) {
          return e.toString();
        }
      },
    );
  }
}

class _AnimatedVehicleTile extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final VehicleStockModel stock;
  final VoidCallback onLoadMore;

  const _AnimatedVehicleTile({
    required this.index,
    required this.total,
    required this.controller,
    required this.stock,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final product = stock.product;
    if (product == null) return const SizedBox.shrink();

    final safeTotal = total == 0 ? 1 : total;
    final start = (index / safeTotal) * 0.5;
    final end = (start + 0.5).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: VehicleStockTile(
          product: product,
          stock: stock,
          onLoadMore: onLoadMore,
        ),
      ),
    );
  }
}