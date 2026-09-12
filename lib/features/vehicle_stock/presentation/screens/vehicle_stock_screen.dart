// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mivet_app/core/di/service_locator.dart';
// import 'package:mivet_app/core/errors/app_toast.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
// import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
// import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';
// import 'package:mivet_app/features/inventory/presentation/widgets/add_to_vehicle_dialog.dart';
// import 'package:mivet_app/features/inventory/presentation/widgets/add_product_sheet.dart';
// import 'package:mivet_app/features/inventory/presentation/widgets/inventory_search_bar.dart';
// import 'package:mivet_app/features/inventory/presentation/widgets/inventory_stat_row.dart';
// import 'package:mivet_app/features/inventory/presentation/widgets/product_detail_sheet.dart';
// import 'package:mivet_app/features/inventory/data/products_repository.dart';
// import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
// import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
// import '../../../inventory/domain/models/product_catalog.dart';
// import '../widgets/vehicle_stock_tile.dart';
// import '../widgets/stock_movement_log_sheet.dart';
// import '../widgets/vehicle_setup_form.dart';
// import '../widgets/category_filter_tab.dart';
// import '../widgets/existing_product_picker_sheet.dart';

// class VehicleStockScreen extends StatelessWidget {
//   const VehicleStockScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => sl<VehicleStockCubit>()..loadVehicles(),
//       child: const _VehicleStockView(),
//     );
//   }
// }

// class _VehicleStockView extends StatefulWidget {
//   const _VehicleStockView();

//   @override
//   State<_VehicleStockView> createState() => _VehicleStockViewState();
// }

// class _VehicleStockViewState extends State<_VehicleStockView>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   String _query = '';
//   ProductCatalog _catalog = ProductCatalog.empty;
//   String? _categoryCode;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 650),
//     )..forward();
//     _loadCatalog();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _refresh() {
//     return Future.wait([
//       context.read<VehicleStockCubit>().refresh(),
//       _loadCatalog(),
//     ]);
//   }

//   Future<void> _loadCatalog() async {
//     try {
//       final results = await Future.wait([
//         ProductsRepository.instance.getCategories(),
//         ProductsRepository.instance.getUnits(),
//       ]);
//       if (!mounted) return;
//       setState(() {
//         _catalog = ProductCatalog(categories: results[0], units: results[1]);
//       });
//     } catch (error) {
//       if (mounted) showAppError(context, error);
//     }
//   }

//   Future<void> _openProductDetail(ProductModel product) async {
//     final changed = await showProductDetailSheet(
//       context,
//       product,
//       catalog: _catalog,
//     );
//     if (changed && mounted) {
//       await context.read<VehicleStockCubit>().refresh();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: context.colors.background,
//       child: SafeArea(
//         child: BlocConsumer<VehicleStockCubit, VehicleStockState>(
//           listener: (context, state) {
//             if (state.successMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.successMessage!)),
//               );
//               context.read<VehicleStockCubit>().clearMessages();
//             }

//             if (state.errorMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.errorMessage!)),
//               );
//               context.read<VehicleStockCubit>().clearMessages();
//             }
//           },
//           builder: (context, state) {
//             if (state.status == VehicleStockStatus.initial ||
//                 state.status == VehicleStockStatus.loading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (state.vehicles.isEmpty) {
//               return VehicleSetupForm(
//                 representativeName: context.select<AuthCubit, String>(
//                   (cubit) => cubit.state.user?.name ?? 'المندوب الحالي',
//                 ),
//               );
//             }

//             final selectedVehicle = state.selectedVehicle;
//             if (selectedVehicle == null) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final filtered = state.vehicleStock.where((entry) {
//               final product = entry.product;
//               if (product == null) return false;
//               final matchesQuery = _query.isEmpty ||
//                   product.name.toLowerCase().contains(_query.toLowerCase());
//               return matchesQuery &&
//                   (_categoryCode == null || product.category == _categoryCode);
//             }).toList();

//             final total = state.vehicleStock.length;
//             final available = state.vehicleStock
//                 .where((item) => item.quantity > item.minThreshold)
//                 .length;
//             final low = state.vehicleStock
//                 .where((item) =>
//                     item.quantity > 0 && item.quantity <= item.minThreshold)
//                 .length;
//             final outOfStock =
//                 state.vehicleStock.where((item) => item.quantity == 0).length;

//             return RefreshIndicator(
//               onRefresh: _refresh,
//               child: ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 14.w,
//                             vertical: 12.h,
//                           ),
//                           decoration: BoxDecoration(
//                             color: context.colors.surface,
//                             borderRadius: BorderRadius.circular(14.r),
//                             border: Border.all(
//                               color: context.colors.border,
//                             ),
//                           ),
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<String>(
//                               value: selectedVehicle.id,
//                               isExpanded: true,
//                               icon: Icon(
//                                 Icons.keyboard_arrow_down_rounded,
//                                 color: context.colors.textMuted,
//                               ),
//                               dropdownColor: context.colors.surface,
//                               items: state.vehicles
//                                   .map(
//                                     (vehicle) => DropdownMenuItem<String>(
//                                       value: vehicle.id,
//                                       child: Text(
//                                         '${vehicle.plateNumber} — ${vehicle.driverName}',
//                                         overflow: TextOverflow.ellipsis,
//                                         style: AppTextStyles.cairoMedium16
//                                             .copyWith(
//                                           color: context.colors.text,
//                                           fontSize: 13.sp,
//                                         ),
//                                       ),
//                                     ),
//                                   )
//                                   .toList(),
//                               onChanged: (vehicleId) {
//                                 if (vehicleId != null) {
//                                   context
//                                       .read<VehicleStockCubit>()
//                                       .selectVehicle(vehicleId);
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 10.w),
//                       Material(
//                         color: context.colors.surface,
//                         borderRadius: BorderRadius.circular(14.r),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(14.r),
//                           onTap: () => showStockMovementLogSheet(
//                             context,
//                             state.movements,
//                           ),
//                           child: Container(
//                             width: 52.h,
//                             height: 52.h,
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(14.r),
//                               border: Border.all(
//                                 color: context.colors.border,
//                               ),
//                             ),
//                             child: Icon(
//                               Icons.history_rounded,
//                               color: context.colors.primary,
//                               size: 20.sp,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 14.h),
//                   InventoryStatRow(
//                     total: total,
//                     available: available,
//                     low: low,
//                     outOfStock: outOfStock,
//                   ),
//                   SizedBox(height: 14.h),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'التصنيفات',
//                           style: AppTextStyles.cairoMedium16.copyWith(
//                             color: context.colors.text,
//                             fontSize: 13.sp,
//                           ),
//                         ),
//                       ),
//                       FilledButton.icon(
//                         onPressed: () => _openProductFlow(
//                           context,
//                           selectedVehicle.id,
//                         ),
//                         icon: const Icon(Icons.add),
//                         label: const Text('إضافة صنف'),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10.h),
//                   SizedBox(
//                     height: 38.h,
//                     child: ListView(
//                       scrollDirection: Axis.horizontal,
//                       children: [
//                         CategoryFilterTab(
//                           label: 'الكل',
//                           selected: _categoryCode == null,
//                           onTap: () => setState(() => _categoryCode = null),
//                         ),
//                         for (final category in _catalog.categories)
//                           Padding(
//                             padding: EdgeInsets.only(left: 8.w),
//                             child: CategoryFilterTab(
//                               label: category.name,
//                               selected: _categoryCode == category.code,
//                               onTap: () => setState(
//                                 () => _categoryCode = category.code,
//                               ),
//                             ),
//                           ),
//                         Padding(
//                           padding: EdgeInsets.only(left: 8.w),
//                           child: CategoryFilterTab(
//                             label: '+',
//                             selected: false,
//                             onTap: _createCategory,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 14.h),
//                   InventorySearchBar(
//                     onChanged: (value) {
//                       setState(() => _query = value);
//                     },
//                   ),
//                   SizedBox(height: 14.h),
//                   if (state.status == VehicleStockStatus.loadingStock)
//                     const LinearProgressIndicator(),
//                   SizedBox(height: 8.h),
//                   if (filtered.isEmpty)
//                     Padding(
//                       padding: EdgeInsets.only(top: 60.h),
//                       child: Center(
//                         child: Text(
//                           state.vehicleStock.isEmpty
//                               ? 'لسه مفيش أصناف محملة في العربية'
//                               : 'لا توجد أصناف مطابقة للبحث',
//                           style: AppTextStyles.cairoMedium16.copyWith(
//                             color: context.colors.textMuted,
//                             fontSize: 13.sp,
//                           ),
//                         ),
//                       ),
//                     )
//                   else
//                     for (int i = 0; i < filtered.length; i++)
//                       _AnimatedVehicleTile(
//                         index: i,
//                         total: filtered.length,
//                         controller: _controller,
//                         stock: filtered[i],
//                         categoryName: _catalog
//                             .categoryName(filtered[i].product!.category),
//                         unitName:
//                             _catalog.unitName(filtered[i].product!.unit),
//                         onTap: () => _openProductDetail(filtered[i].product!),
//                         onLoadMore: () => _loadMore(
//                           context,
//                           selectedVehicle.id,
//                           filtered[i],
//                         ),
//                       ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Future<void> _createCategory() async {
//     final controller = TextEditingController();
//     final name = await showDialog<String>(
//       context: context,
//       builder: (dialog) => AlertDialog(
//         title: const Text('إنشاء تصنيف'),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           textAlign: TextAlign.right,
//           decoration: const InputDecoration(labelText: 'اسم التصنيف'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialog),
//             child: const Text('إلغاء'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(dialog, controller.text),
//             child: const Text('إنشاء'),
//           ),
//         ],
//       ),
//     );

//     Future.delayed(const Duration(milliseconds: 300), () => controller.dispose());

//     if (name == null || name.trim().isEmpty) return;
//     try {
//       final category = await ProductsRepository.instance.createCategory(name);
//       if (mounted) {
//         setState(() {
//           _catalog = _catalog.copyWith(
//             categories: [..._catalog.categories, category],
//           );
//           _categoryCode = category.code;
//         });
//       }
//     } catch (error) {
//       if (mounted) showAppError(context, error);
//     }
//   }

//   Future<void> _openProductFlow(BuildContext context, String vehicleId) async {
//     final choice = await showModalBottomSheet<bool>(
//       context: context,
//       builder: (sheetContext) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.search_rounded),
//               title: const Text('اختيار صنف موجود'),
//               onTap: () => Navigator.pop(sheetContext, true),
//             ),
//             ListTile(
//               leading: const Icon(Icons.add_box_outlined),
//               title: const Text('إنشاء صنف جديد'),
//               onTap: () => Navigator.pop(sheetContext, false),
//             ),
//           ],
//         ),
//       ),
//     );
//     if (!context.mounted || choice == null) return;
//     if (choice) {
//       final product = await showModalBottomSheet<ProductModel>(
//         context: context,
//         isScrollControlled: true,
//         builder: (_) => ExistingProductPickerSheet(
//           loadProducts: ProductsRepository.instance.getProducts,
//           catalog: _catalog,
//         ),
//       );
//       if (product != null && context.mounted) {
//         await _loadProduct(context, vehicleId, product);
//       }
//       return;
//     }
//     await showAddProductSheet(
//       context,
//       initialVehicleQuantity: 1,
//       onCreated: (product, quantity) =>
//           context.read<VehicleStockCubit>().loadStock(
//                 vehicleId: vehicleId,
//                 productId: product.id,
//                 quantity: quantity,
//                 minThreshold: product.minStockThreshold,
//               ),
//     );
//   }

//   Future<void> _loadProduct(
//     BuildContext context,
//     String vehicleId,
//     ProductModel product,
//   ) =>
//       showAddToVehicleDialog(
//         context,
//         product: product,
//         onConfirm: (quantity, minThreshold) async {
//           try {
//             await context.read<VehicleStockCubit>().loadStock(
//                   vehicleId: vehicleId,
//                   productId: product.id,
//                   quantity: quantity,
//                   minThreshold: minThreshold,
//                 );
//             return null;
//           } catch (error) {
//             return error.toString();
//           }
//         },
//       );

//   Future<void> _loadMore(
//     BuildContext context,
//     String vehicleId,
//     VehicleStockModel stock,
//   ) async {
//     final product = stock.product;
//     if (product == null) return;

//     await showAddToVehicleDialog(
//       context,
//       product: product,
//       onConfirm: (quantity, minThreshold) async {
//         try {
//           await context.read<VehicleStockCubit>().loadStock(
//                 vehicleId: vehicleId,
//                 productId: product.id,
//                 quantity: quantity,
//                 minThreshold: minThreshold,
//               );
//           return null;
//         } catch (e) {
//           return e.toString();
//         }
//       },
//     );
//   }
// }

// class _AnimatedVehicleTile extends StatelessWidget {
//   final int index;
//   final int total;
//   final AnimationController controller;
//   final VehicleStockModel stock;
//   final String categoryName;
//   final String unitName;
//   final VoidCallback onTap;
//   final VoidCallback onLoadMore;

//   const _AnimatedVehicleTile({
//     required this.index,
//     required this.total,
//     required this.controller,
//     required this.stock,
//     required this.categoryName,
//     required this.unitName,
//     required this.onTap,
//     required this.onLoadMore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final product = stock.product;
//     if (product == null) return const SizedBox.shrink();

//     final safeTotal = total == 0 ? 1 : total;
//     final start = (index / safeTotal) * 0.5;
//     final end = (start + 0.5).clamp(0.0, 1.0);

//     final animation = CurvedAnimation(
//       parent: controller,
//       curve: Interval(
//         start,
//         end,
//         curve: Curves.easeOutCubic,
//       ),
//     );

//     return AnimatedBuilder(
//       animation: animation,
//       builder: (context, child) {
//         return Opacity(
//           opacity: animation.value.clamp(0.0, 1.0),
//           child: Transform.translate(
//             offset: Offset(0, 16 * (1 - animation.value)),
//             child: child,
//           ),
//         );
//       },
//       child: Padding(
//         padding: EdgeInsets.only(bottom: 12.h),
//         child: VehicleStockTile(
//           product: product,
//           stock: stock,
//           categoryName: categoryName,
//           unitName: unitName,
//           onTap: onTap,
//           onLoadMore: onLoadMore,
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_cubit.dart';
import 'package:mivet_app/features/inventory/presentation/cubit/vehicle_stock_state.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/add_to_vehicle_dialog.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/add_product_sheet.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/inventory_search_bar.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/inventory_stat_row.dart';
import 'package:mivet_app/features/inventory/presentation/widgets/product_detail_sheet.dart';
import 'package:mivet_app/features/inventory/data/products_repository.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import '../../../inventory/domain/models/product_catalog.dart';
import '../widgets/vehicle_stock_tile.dart';
import '../widgets/stock_movement_log_sheet.dart';
import '../widgets/vehicle_setup_form.dart';
import '../widgets/category_filter_tab.dart';
import '../widgets/existing_product_picker_sheet.dart';

class VehicleStockScreen extends StatefulWidget {
  const VehicleStockScreen({super.key});

  @override
  State<VehicleStockScreen> createState() => _VehicleStockScreenState();
}

class _VehicleStockScreenState extends State<VehicleStockScreen> {
  late final VehicleStockCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<VehicleStockCubit>();
    _cubit.loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
  ProductCatalog _catalog = ProductCatalog.empty;
  String? _categoryCode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loadCatalog();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return Future.wait([
      context.read<VehicleStockCubit>().refresh(),
      _loadCatalog(),
    ]);
  }

  Future<void> _loadCatalog() async {
    try {
      final results = await Future.wait([
        ProductsRepository.instance.getCategories(),
        ProductsRepository.instance.getUnits(),
      ]);
      if (!mounted) return;
      setState(() {
        _catalog = ProductCatalog(categories: results[0], units: results[1]);
      });
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _openProductDetail(ProductModel product) async {
    final changed = await showProductDetailSheet(
      context,
      product,
      catalog: _catalog,
    );
    if (changed && mounted) {
      await context.read<VehicleStockCubit>().refresh();
    }
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
              return VehicleSetupForm(
                representativeName: context.select<AuthCubit, String>(
                  (cubit) => cubit.state.user?.name ?? 'المندوب الحالي',
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
              final matchesQuery = _query.isEmpty ||
                  product.name.toLowerCase().contains(_query.toLowerCase());
              return matchesQuery &&
                  (_categoryCode == null || product.category == _categoryCode);
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'التصنيفات',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.text,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openProductFlow(
                          context,
                          selectedVehicle.id,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة صنف'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 38.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CategoryFilterTab(
                          label: 'الكل',
                          selected: _categoryCode == null,
                          onTap: () => setState(() => _categoryCode = null),
                        ),
                        for (final category in _catalog.categories)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: CategoryFilterTab(
                              label: category.name,
                              selected: _categoryCode == category.code,
                              onTap: () => setState(
                                () => _categoryCode = category.code,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: CategoryFilterTab(
                            label: '+',
                            selected: false,
                            onTap: _createCategory,
                          ),
                        ),
                      ],
                    ),
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
                        categoryName: _catalog
                            .categoryName(filtered[i].product!.category),
                        unitName: _catalog.unitName(filtered[i].product!.unit),
                        onTap: () => _openProductDetail(filtered[i].product!),
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

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('إنشاء تصنيف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'اسم التصنيف'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );

    Future.delayed(
        const Duration(milliseconds: 300), () => controller.dispose());

    if (name == null || name.trim().isEmpty) return;
    try {
      final category = await ProductsRepository.instance.createCategory(name);
      if (mounted) {
        setState(() {
          _catalog = _catalog.copyWith(
            categories: [..._catalog.categories, category],
          );
          _categoryCode = category.code;
        });
      }
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _openProductFlow(BuildContext context, String vehicleId) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text('اختيار صنف موجود'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('إنشاء صنف جديد'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice) {
      final product = await showModalBottomSheet<ProductModel>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ExistingProductPickerSheet(
          loadProducts: ProductsRepository.instance.getProducts,
          catalog: _catalog,
        ),
      );
      if (product != null && context.mounted) {
        await _loadProduct(context, vehicleId, product);
      }
      return;
    }
    await showAddProductSheet(
      context,
      initialVehicleQuantity: 1,
      onCreated: (product, quantity) =>
          context.read<VehicleStockCubit>().loadStock(
                vehicleId: vehicleId,
                productId: product.id,
                quantity: quantity,
                minThreshold: product.minStockThreshold,
              ),
    );
  }

  Future<void> _loadProduct(
    BuildContext context,
    String vehicleId,
    ProductModel product,
  ) =>
      showAddToVehicleDialog(
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
          } catch (error) {
            return error.toString();
          }
        },
      );

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
  final String categoryName;
  final String unitName;
  final VoidCallback onTap;
  final VoidCallback onLoadMore;

  const _AnimatedVehicleTile({
    required this.index,
    required this.total,
    required this.controller,
    required this.stock,
    required this.categoryName,
    required this.unitName,
    required this.onTap,
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
          categoryName: categoryName,
          unitName: unitName,
          onTap: onTap,
          onLoadMore: onLoadMore,
        ),
      ),
    );
  }
}
