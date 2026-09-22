============================================================
FILE: lib/features/vehicle_stock/presentation/screens/vehicle_stock_screen.dart
============================================================
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
                  (cubit) => cubit.state.user?.name ?? 'ط§ظ„ظ…ظ†ط¯ظˆط¨ ط§ظ„ط­ط§ظ„ظٹ',
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
                                        '${vehicle.plateNumber} â€” ${vehicle.driverName}',
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
                          'ط§ظ„طھطµظ†ظٹظپط§طھ',
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
                        label: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ'),
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
                          label: 'ط§ظ„ظƒظ„',
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
                              ? 'ظ„ط³ظ‡ ظ…ظپظٹط´ ط£طµظ†ط§ظپ ظ…ط­ظ…ظ„ط© ظپظٹ ط§ظ„ط¹ط±ط¨ظٹط©'
                              : 'ظ„ط§ طھظˆط¬ط¯ ط£طµظ†ط§ظپ ظ…ط·ط§ط¨ظ‚ط© ظ„ظ„ط¨ط­ط«',
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
        title: const Text('ط¥ظ†ط´ط§ط، طھطµظ†ظٹظپ'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„طھطµظ†ظٹظپ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('ط¥ظ„ط؛ط§ط،'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text),
            child: const Text('ط¥ظ†ط´ط§ط،'),
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
              title: const Text('ط§ط®طھظٹط§ط± طµظ†ظپ ظ…ظˆط¬ظˆط¯'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('ط¥ظ†ط´ط§ط، طµظ†ظپ ط¬ط¯ظٹط¯'),
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


============================================================
FILE: lib/features/inventory/data/products_repository.dart
============================================================
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/product_catalog_item.dart';
import '../domain/models/product_model.dart';

class ProductsRepository {
  ProductsRepository._();

  static final instance = ProductsRepository._();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const productImageBucket = 'product-images';
  static const _productFields =
      'id, name, image_path, category, unit, retail_price, wholesale_price, '
      'min_stock_threshold, expiry_date, created_at, deleted_at';

  Future<List<ProductCatalogItem>> getCategories() =>
      _getCatalog('product_categories');

  Future<List<ProductCatalogItem>> getUnits() => _getCatalog('product_units');

  Future<List<ProductCatalogItem>> _getCatalog(String table) async {
    final rows = await _supabase.from(table).select('code, name').order('name');
    return (rows as List)
        .map((row) =>
            ProductCatalogItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ProductCatalogItem> createCategory(String name) =>
      _createCatalog('product_categories', name, 'category');

  Future<ProductCatalogItem> createUnit(String name) =>
      _createCatalog('product_units', name, 'unit');

  Future<ProductCatalogItem> _createCatalog(
    String table,
    String name,
    String prefix,
  ) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('ط§ظ„ط§ط³ظ… ظ…ط·ظ„ظˆط¨');
    final code = '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
    final row = await _supabase
        .from(table)
        .insert({'code': code, 'name': cleanName})
        .select('code, name')
        .single();
    return ProductCatalogItem.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> uploadProductImage(String localPath) async {
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${localPath.split(Platform.pathSeparator).last}';

    final storagePath = 'products/$fileName';

    await _supabase.storage
        .from(productImageBucket)
        .upload(storagePath, File(localPath));

    return _supabase.storage.from(productImageBucket).getPublicUrl(storagePath);
  }

  Future<void> deleteProductImage(String imagePath) async {
    const marker = '/storage/v1/object/public/$productImageBucket/';

    final index = imagePath.indexOf(marker);

    if (index == -1) return;

    final storagePath = imagePath.substring(index + marker.length);

    await _supabase.storage.from(productImageBucket).remove([storagePath]);
  }

  Future<List<ProductModel>> getProducts() async {
    final rows = await _supabase
        .from('products')
        .select(_productFields)
        .isFilter('deleted_at', null)
        .order('name', ascending: true);

    return (rows as List)
        .map(
          (row) => _fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      final row = await _supabase
          .from('products')
          .select(_productFields)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return _fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      return null;
    }
  }

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required String unit,
    required double retailPrice,
    required double wholesalePrice,
    required int minStockThreshold,
    String? imagePath,
    DateTime? expiryDate,
  }) async {
    final row = await _supabase
        .from('products')
        .insert({
          'name': name,
          'category': category,
          'unit': unit,
          'retail_price': retailPrice,
          'wholesale_price': wholesalePrice,
          'min_stock_threshold': minStockThreshold,
          if (imagePath != null) 'image_path': imagePath,
          if (expiryDate != null) 'expiry_date': _dateOnly(expiryDate),
        })
        .select(_productFields)
        .single();

    return _fromRow(row);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final row = await _supabase
        .from('products')
        .update({
          'name': product.name,
          'category': product.category,
          'unit': product.unit,
          'retail_price': product.retailPrice,
          'wholesale_price': product.wholesalePrice,
          'min_stock_threshold': product.minStockThreshold,
          'image_path': product.imagePath,
          'expiry_date': product.expiryDate == null
              ? null
              : _dateOnly(product.expiryDate!),
        })
        .eq('id', product.id)
        .select(_productFields)
        .single();

    return _fromRow(row);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').update(
        {'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  ProductModel _fromRow(Map<String, dynamic> row) => ProductModel.fromMap(row);

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}


============================================================
FILE: lib/features/inventory/domain/models/product_model.dart
============================================================
const Object _unset = Object();

class ProductModel {
  final String id;
  final String name;
  final String? imagePath;

  /// Database codes referencing product_categories.code and product_units.code.
  final String category;
  final String unit;
  final double retailPrice;
  final double wholesalePrice;
  final int minStockThreshold;
  final DateTime? expiryDate;
  final DateTime createdAt;

  /// Soft-delete timestamp. Non-null means the product is logically deleted.
  final DateTime? deletedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.imagePath,
    required this.category,
    required this.unit,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.minStockThreshold,
    this.expiryDate,
    required this.createdAt,
    this.deletedAt,
  });

  /// Whether this product has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  double get basePrice => retailPrice;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['image_path'] as String?,
      category: map['category'] as String,
      unit: map['unit'] as String,
      retailPrice: (map['retail_price'] as num).toDouble(),
      wholesalePrice: (map['wholesale_price'] as num).toDouble(),
      minStockThreshold: (map['min_stock_threshold'] as num).toInt(),
      expiryDate: map['expiry_date'] == null
          ? null
          : DateTime.parse(map['expiry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry => expiryDate?.difference(DateTime.now()).inDays;

  ProductModel copyWith({
    String? name,
    Object? imagePath = _unset,
    String? category,
    String? unit,
    double? retailPrice,
    double? wholesalePrice,
    int? minStockThreshold,
    Object? expiryDate = _unset,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      expiryDate:
          expiryDate == _unset ? this.expiryDate : expiryDate as DateTime?,
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }
}


============================================================
FILE: lib/features/inventory/domain/models/product_catalog.dart
============================================================
import 'product_catalog_item.dart';

class ProductCatalog {
  final List<ProductCatalogItem> categories;
  final List<ProductCatalogItem> units;

  const ProductCatalog({
    this.categories = const [],
    this.units = const [],
  });

  static const empty = ProductCatalog();

  String categoryName(String code) => _nameFor(categories, code);

  String unitName(String code) => _nameFor(units, code);

  String _nameFor(List<ProductCatalogItem> items, String code) {
    for (final item in items) {
      if (item.code == code) return item.name;
    }
    return code;
  }

  ProductCatalog copyWith({
    List<ProductCatalogItem>? categories,
    List<ProductCatalogItem>? units,
  }) {
    return ProductCatalog(
      categories: categories ?? this.categories,
      units: units ?? this.units,
    );
  }
}


============================================================
FILE: lib/features/inventory/domain/models/product_catalog_item.dart
============================================================
/// A catalog record stored in Supabase. [code] is what products persist and
/// [name] is the human-readable Arabic label shown in the application.
class ProductCatalogItem {
  final String code;
  final String name;

  const ProductCatalogItem({required this.code, required this.name});

  factory ProductCatalogItem.fromMap(Map<String, dynamic> map) {
    return ProductCatalogItem(
      code: map['code'] as String,
      name: (map['name'] ?? map['label'] ?? map['code']) as String,
    );
  }
}


============================================================
FILE: lib/features/inventory/presentation/widgets/product_detail_sheet.dart
============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/core/widgets/custom_alert_dialog.dart';
import '../../data/products_repository.dart';
import '../../domain/models/product_catalog.dart';
import '../../domain/models/product_model.dart';
import 'add_product_sheet.dart';

Future<bool> showProductDetailSheet(
  BuildContext context,
  ProductModel product, {
  ProductCatalog catalog = ProductCatalog.empty,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProductDetailSheet(
      product: product,
      catalog: catalog,
    ),
  );
  return changed ?? false;
}

class ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final ProductCatalog catalog;

  const ProductDetailSheet({
    super.key,
    required this.product,
    this.catalog = ProductCatalog.empty,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late ProductModel _product;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _editProduct() async {
    final updated = await showAddProductSheet(context, productToEdit: _product);
    if (!mounted || updated == null) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => CustomAlertDialog(
        title: 'ط­ط°ظپ ط§ظ„ظ…ظ†طھط¬',
        content:
            'ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯ ظ…ظ† ط­ط°ظپ "${_product.name}"طں ظ„ط§ ظٹظ…ظƒظ† ط§ظ„طھط±ط§ط¬ط¹ ط¹ظ† ظ‡ط°ط§ ط§ظ„ط¥ط¬ط±ط§ط،.',
        primaryButtonText: 'ط­ط°ظپ',
        secondaryButtonText: 'ط¥ظ„ط؛ط§ط،',
        primaryButtonColor: dialogContext.colors.statusNotReached,
        onPrimaryPressed: () => _performDelete(dialogContext),
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _performDelete(BuildContext dialogContext) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await ProductsRepository.instance.deleteProduct(_product.id);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (!mounted) return;
      showAppSuccess(context, 'طھظ… ط­ط°ظپ ط§ظ„طµظ†ظپ ط¨ظ†ط¬ط§ط­');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (mounted) {
        setState(() => _deleting = false);
        showAppError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;
    final categoryName = widget.catalog.categoryName(product.category);
    final unitName = widget.catalog.unitName(product.unit);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? product.imagePath!.startsWith('http')
                            ? Image.network(product.imagePath!,
                                fit: BoxFit.cover)
                            : Image.file(File(product.imagePath!),
                                fit: BoxFit.cover)
                        : Icon(Icons.medication_liquid_outlined,
                            color: context.colors.primary, size: 26.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: AppTextStyles.cairoBold18.copyWith(
                                color: context.colors.text, fontSize: 16.sp)),
                        SizedBox(height: 4.h),
                        Text(categoryName,
                            style: AppTextStyles.almaraiRegular14.copyWith(
                                color: context.colors.textMuted,
                                fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'ط³ط¹ط± ط§ظ„طھط¬ط²ط¦ط©',
                  value: '${product.retailPrice.toStringAsFixed(0)} ط¬.ظ…'),
              _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'ط³ط¹ط± ط§ظ„ط¬ظ…ظ„ط©',
                  value: '${product.wholesalePrice.toStringAsFixed(0)} ط¬.ظ…'),
              _DetailRow(
                  icon: Icons.straighten_rounded,
                  label: 'ظˆط­ط¯ط© ط§ظ„ظ‚ظٹط§ط³',
                  value: unitName),
              _DetailRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'ط§ظ„ط­ط¯ ط§ظ„ط£ط¯ظ†ظ‰ ظ„ظ„ظ…ط®ط²ظˆظ†',
                  value: '${product.minStockThreshold} $unitName'),
              _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'طھط§ط±ظٹط® ط§ظ„ط¥ط¶ط§ظپط©',
                  value: DateFormat('yyyy/MM/dd').format(product.createdAt)),
              _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'ظˆظ‚طھ ط§ظ„ط¥ط¶ط§ظپط©',
                  value: DateFormat('hh:mm a').format(product.createdAt)),
              if (product.expiryDate != null)
                _DetailRow(
                  icon: Icons.event_busy_outlined,
                  label: 'طھط§ط±ظٹط® ط§ظ„طµظ„ط§ط­ظٹط©',
                  value: DateFormat('yyyy/MM/dd').format(product.expiryDate!),
                ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: context.colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: _deleting ? null : _editProduct,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: context.colors.primary, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('طھط¹ط¯ظٹظ„',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.primary,
                                      fontSize: 13.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Material(
                      color: context.colors.statusNotReached.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: _deleting ? null : _confirmDelete,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _deleting
                                  ? SizedBox(
                                      width: 16.sp,
                                      height: 16.sp,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colors.statusNotReached,
                                      ),
                                    )
                                  : Icon(Icons.delete_outline_rounded,
                                      color: context.colors.statusNotReached,
                                      size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('ط­ط°ظپ',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.statusNotReached,
                                      fontSize: 13.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: context.colors.textMuted),
          SizedBox(width: 8.w),
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: context.colors.text, fontSize: 12.sp)),
        ],
      ),
    );
  }
}


============================================================
FILE: lib/features/inventory/presentation/widgets/add_product_sheet.dart
============================================================
import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../data/products_repository.dart';
import '../../domain/models/product_catalog_item.dart';
import '../../domain/models/product_model.dart';
import 'product_image_picker.dart';

Future<ProductModel?> showAddProductSheet(
  BuildContext context, {
  ProductModel? productToEdit,
  int? initialVehicleQuantity,
  Future<void> Function(ProductModel product, int quantity)? onCreated,
}) =>
    showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(
        productToEdit: productToEdit,
        initialVehicleQuantity: initialVehicleQuantity,
        onCreated: onCreated,
      ),
    );

class _AddProductSheet extends StatefulWidget {
  final ProductModel? productToEdit;
  final int? initialVehicleQuantity;
  final Future<void> Function(ProductModel product, int quantity)? onCreated;
  const _AddProductSheet(
      {this.productToEdit, this.initialVehicleQuantity, this.onCreated});
  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _repository = ProductsRepository.instance;
  late final _name =
      TextEditingController(text: widget.productToEdit?.name ?? '');
  late final _retail = TextEditingController(
      text: widget.productToEdit?.retailPrice.toStringAsFixed(2) ?? '');
  late final _wholesale = TextEditingController(
      text: widget.productToEdit?.wholesalePrice.toStringAsFixed(2) ?? '');
  late final _threshold = TextEditingController(
      text: '${widget.productToEdit?.minStockThreshold ?? 5}');
  late final _quantity = TextEditingController(
      text: widget.initialVehicleQuantity?.toString() ?? '');
  List<ProductCatalogItem> _categories = const [], _units = const [];
  String? _category, _unit, _imagePath;
  DateTime? _expiryDate;
  bool _loadingCatalog = true, _saving = false;
  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.productToEdit?.imagePath;
    _expiryDate = widget.productToEdit?.expiryDate;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final results = await Future.wait(
          [_repository.getCategories(), _repository.getUnits()]);
      if (!mounted) return;
      final categories = results[0];
      final units = results[1];
      setState(() {
        _categories = categories;
        _units = units;
        _category = widget.productToEdit?.category ??
            (categories.isEmpty ? null : categories.first.code);
        _unit = widget.productToEdit?.unit ??
            (units.isEmpty ? null : units.first.code);
        _loadingCatalog = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadingCatalog = false);
        showAppError(context, error);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _retail, _wholesale, _threshold, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _createCatalog(bool isCategory) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(isCategory ? 'ط¥ظ†ط´ط§ط، طھطµظ†ظٹظپ' : 'ط¥ط¶ط§ظپط© ظˆط­ط¯ط© ظ‚ظٹط§ط³'),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                      labelText: isCategory ? 'ط§ط³ظ… ط§ظ„طھطµظ†ظٹظپ' : 'ط§ط³ظ… ط§ظ„ظˆط­ط¯ط©')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('ط¥ظ„ط؛ط§ط،')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, controller.text),
                    child: const Text('ط¥ظ†ط´ط§ط،'))
              ],
            ));

    Future.delayed(
        const Duration(milliseconds: 300), () => controller.dispose());

    if (name == null || name.trim().isEmpty) return;
    try {
      final item = isCategory
          ? await _repository.createCategory(name)
          : await _repository.createUnit(name);
      if (!mounted) return;
      setState(() {
        if (isCategory) {
          _categories = [..._categories, item];
          _category = item.code;
        } else {
          _units = [..._units, item];
          _unit = item.code;
        }
      });
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _submit() async {
    final retail = double.tryParse(_retail.text.trim());
    final wholesale = double.tryParse(_wholesale.text.trim());
    final threshold = int.tryParse(_threshold.text.trim());
    final quantity = widget.initialVehicleQuantity == null
        ? 1
        : int.tryParse(_quantity.text.trim());
    if (_name.text.trim().isEmpty ||
        _category == null ||
        _unit == null ||
        retail == null ||
        wholesale == null ||
        threshold == null ||
        quantity == null ||
        retail < 0 ||
        wholesale < 0 ||
        threshold < 0 ||
        quantity <= 0 ||
        wholesale > retail) {
      showAppError(
          context, Exception('ط¨ط±ط¬ط§ط، ط¥ط¯ط®ط§ظ„ ط¨ظٹط§ظ†ط§طھ ط§ظ„طµظ†ظپ ظˆط§ظ„ظƒظ…ظٹط© ط¨ط´ظƒظ„ طµط­ظٹط­'));
      return;
    }
    setState(() => _saving = true);
    String? uploaded;
    var productCreated = false;
    try {
      var image = _imagePath;
      if (image != null && !image.startsWith('http')) {
        uploaded = await _repository.uploadProductImage(image);
        image = uploaded;
      }
      final product = _isEditing
          ? await _repository.updateProduct(widget.productToEdit!.copyWith(
              name: _name.text.trim(),
              imagePath: image,
              category: _category,
              unit: _unit,
              retailPrice: retail,
              wholesalePrice: wholesale,
              minStockThreshold: threshold,
              expiryDate: _expiryDate))
          : await _repository.createProduct(
              name: _name.text.trim(),
              category: _category!,
              unit: _unit!,
              retailPrice: retail,
              wholesalePrice: wholesale,
              minStockThreshold: threshold,
              imagePath: image,
              expiryDate: _expiryDate);
      productCreated = !_isEditing;
      if (!_isEditing && widget.onCreated != null) {
        await widget.onCreated!(product, quantity);
      }
      if (mounted) Navigator.pop(context, product);
    } catch (error) {
      if (uploaded != null && !productCreated) {
        try {
          await _repository.deleteProductImage(uploaded);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _saving = false);
        showAppError(context, error);
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate:
            _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
    if (date != null && mounted) setState(() => _expiryDate = date);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .9,
        minChildSize: .5,
        maxChildSize: .96,
        expand: false,
        builder: (context, scroll) => Container(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
          decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
          child: _loadingCatalog
              ? const Center(child: CircularProgressIndicator())
              : ListView(controller: scroll, children: [
                  Center(
                      child: Container(
                          width: 42.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                              color: context.colors.border,
                              borderRadius: BorderRadius.circular(10.r)))),
                  SizedBox(height: 14.h),
                  Text(_isEditing ? 'طھط¹ط¯ظٹظ„ ط§ظ„طµظ†ظپ' : 'ط¥ط¶ط§ظپط© طµظ†ظپ ط¬ط¯ظٹط¯',
                      style: AppTextStyles.cairoBold18.copyWith(
                          color: context.colors.text, fontSize: 16.sp)),
                  SizedBox(height: 16.h),
                  ProductImagePicker(
                      imagePath: _imagePath,
                      onChanged: (value) => setState(() => _imagePath = value)),
                  SizedBox(height: 16.h),
                  _field('ط§ط³ظ… ط§ظ„طµظ†ظپ', _name, text: true),
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(
                        child: _field('ط³ط¹ط± ط§ظ„طھط¬ط²ط¦ط©', _retail, decimal: true)),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: _field('ط³ط¹ط± ط§ظ„ط¬ظ…ظ„ط©', _wholesale, decimal: true))
                  ]),
                  SizedBox(height: 12.h),
                  _field('ط§ظ„ط­ط¯ ط§ظ„ط£ط¯ظ†ظ‰ ظ„ظ„ظ…ط®ط²ظˆظ†', _threshold),
                  if (widget.initialVehicleQuantity != null) ...[
                    SizedBox(height: 12.h),
                    _field('ط§ظ„ظƒظ…ظٹط© ط§ظ„ط£ظˆظ„ظٹط© ظ„ظ„ط¹ط±ط¨ظٹط©', _quantity)
                  ],
                  SizedBox(height: 12.h),
                  _dropdown(
                      'ط§ظ„طھطµظ†ظٹظپ',
                      _categories,
                      _category,
                      (value) => setState(() => _category = value),
                      () => _createCatalog(true),
                      'ط¥ط¶ط§ظپط© طھطµظ†ظٹظپ'),
                  SizedBox(height: 12.h),
                  _dropdown(
                      'ظˆط­ط¯ط© ط§ظ„ظ‚ظٹط§ط³',
                      _units,
                      _unit,
                      (value) => setState(() => _unit = value),
                      () => _createCatalog(false),
                      'ط¥ط¶ط§ظپط© ظˆط­ط¯ط© ظ‚ظٹط§ط³'),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                      onPressed: _pickExpiryDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_expiryDate == null
                          ? 'طھط§ط±ظٹط® ط§ظ„طµظ„ط§ط­ظٹط© (ط§ط®طھظٹط§ط±ظٹ)'
                          : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}')),
                  SizedBox(height: 20.h),
                  FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h)),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isEditing ? 'ط­ظپط¸ ط§ظ„طھط¹ط¯ظٹظ„ط§طھ' : 'ط­ظپط¸ ط§ظ„طµظ†ظپ')),
                ]),
        ),
      );

  Widget _field(String label, TextEditingController controller,
          {bool decimal = false, bool text = false}) =>
      TextField(
          controller: controller,
          keyboardType: text
              ? TextInputType.text
              : decimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: context.colors.surface));
  Widget _dropdown(String label, List<ProductCatalogItem> items, String? value,
          ValueChanged<String?> changed, VoidCallback add, String addLabel) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: context.colors.surface),
            items: items
                .map((item) =>
                    DropdownMenuItem(value: item.code, child: Text(item.name)))
                .toList(),
            onChanged: changed),
        TextButton.icon(
            onPressed: add, icon: const Icon(Icons.add), label: Text(addLabel))
      ]);
}


============================================================
FILE: lib/features/inventory/data/datasources/vehicle_stock_remote_data_source.dart
============================================================
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleStockRemoteDataSource {
  final SupabaseClient _supabase;

  VehicleStockRemoteDataSource(this._supabase);

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final rows = await _supabase
        .from('vehicles')
        .select('id, plate_number, driver_name, rep_id, created_at')
        .order('plate_number', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  }) async {
    final row = await _supabase.rpc(
      'create_vehicle_for_current_rep',
      params: {
        'p_plate_number': plateNumber,
        'p_driver_name': driverName,
      },
    );
    final result = row is List ? row.single : row;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getVehicleStock(
    String vehicleId,
  ) async {
    final rows = await _supabase
        .from('vehicle_stock')
        .select(
          'vehicle_id, product_id, quantity, min_threshold, '
          'products(id, name, image_path, category, unit, retail_price, '
          'wholesale_price, min_stock_threshold, expiry_date, created_at, deleted_at)',
        )
        .eq('vehicle_id', vehicleId)
        .order('product_id', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStockMovements({
    String? vehicleId,
  }) async {
    // FIXED: Include product name in relational query
    var query = _supabase.from('stock_movements').select(
          'id, product_id, vehicle_id, type, quantity, created_by, '
          'created_at, reference_id, note, products(name)',
        );

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) async {
    await _supabase.rpc(
      'load_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_min_threshold': minThreshold,
        'p_note': note,
      },
    );
  }

  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    await _supabase.rpc(
      'deduct_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_reference_id': referenceId,
        'p_note': note,
      },
    );
  }

  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    await _supabase.rpc(
      'return_vehicle_stock',
      params: {
        'p_vehicle_id': vehicleId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_reference_id': referenceId,
        'p_note': note,
      },
    );
  }
}


============================================================
FILE: lib/features/inventory/domain/repositories/vehicle_stock_repository.dart
============================================================
import '../models/delivery_vehicle_model.dart';
import '../models/stock_movement_model.dart';
import '../models/vehicle_stock_model.dart';

abstract class VehicleStockRepository {
  Future<List<DeliveryVehicleModel>> getVehicles();

  Future<DeliveryVehicleModel> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  });

  Future<List<VehicleStockModel>> getVehicleStock(
    String vehicleId,
  );

  Future<List<StockMovementModel>> getStockMovements({
    String? vehicleId,
  });

  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  });

  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  });

  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  });
}


============================================================
FILE: lib/features/inventory/data/repositories/vehicle_stock_repository_impl.dart
============================================================
import '../../data/datasources/vehicle_stock_remote_data_source.dart';
import '../../domain/models/delivery_vehicle_model.dart';
import '../../domain/models/stock_movement_model.dart';
import '../../domain/models/vehicle_stock_model.dart';
import '../../domain/repositories/vehicle_stock_repository.dart';

class VehicleStockRepositoryImpl implements VehicleStockRepository {
  final VehicleStockRemoteDataSource remoteDataSource;

  const VehicleStockRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<DeliveryVehicleModel>> getVehicles() async {
    final rows = await remoteDataSource.getVehicles();
    return rows.map(DeliveryVehicleModel.fromMap).toList();
  }

  @override
  Future<DeliveryVehicleModel> createVehicleForCurrentRep({
    required String plateNumber,
    required String driverName,
  }) async {
    final row = await remoteDataSource.createVehicleForCurrentRep(
      plateNumber: plateNumber,
      driverName: driverName,
    );
    return DeliveryVehicleModel.fromMap(row);
  }

  @override
  Future<List<VehicleStockModel>> getVehicleStock(String vehicleId) async {
    final rows = await remoteDataSource.getVehicleStock(vehicleId);
    return rows
        .map(VehicleStockModel.fromMap)
        .where((stock) => stock.product != null && !stock.product!.isDeleted)
        .toList();
  }

  @override
  Future<List<StockMovementModel>> getStockMovements(
      {String? vehicleId}) async {
    final rows = await remoteDataSource.getStockMovements(vehicleId: vehicleId);
    return rows.map(StockMovementModel.fromMap).toList();
  }

  @override
  Future<void> loadToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) {
    return remoteDataSource.loadToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      minThreshold: minThreshold,
      note: note,
    );
  }

  @override
  Future<void> deductFromVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return remoteDataSource.deductFromVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }

  @override
  Future<void> returnToVehicle({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) {
    return remoteDataSource.returnToVehicle(
      vehicleId: vehicleId,
      productId: productId,
      quantity: quantity,
      referenceId: referenceId,
      note: note,
    );
  }
}


============================================================
FILE: lib/features/inventory/domain/models/vehicle_stock_model.dart
============================================================
import 'product_model.dart';

class VehicleStockModel {
  final String vehicleId;
  final String productId;
  final int quantity;
  final int minThreshold;
  final ProductModel? product;

  const VehicleStockModel({
    required this.vehicleId,
    required this.productId,
    required this.quantity,
    required this.minThreshold,
    this.product,
  });

  bool get isLowStock => quantity <= minThreshold;

  factory VehicleStockModel.fromMap(Map<String, dynamic> map) {
    final productMap = map['products'];

    return VehicleStockModel(
      vehicleId: map['vehicle_id'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toInt(),
      minThreshold: (map['min_threshold'] as num).toInt(),
      product: productMap is Map<String, dynamic>
          ? ProductModel.fromMap(productMap)
          : productMap is Map
              ? ProductModel.fromMap(
                  Map<String, dynamic>.from(productMap),
                )
              : null,
    );
  }
}


============================================================
FILE: lib/features/inventory/presentation/cubit/vehicle_stock_cubit.dart
============================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_movement_model.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';
import 'package:mivet_app/features/inventory/domain/usecases/deduct_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/create_vehicle_for_current_rep.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_stock_movements.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/get_vehicles.dart';
import 'package:mivet_app/features/inventory/domain/usecases/load_vehicle_stock.dart';
import 'package:mivet_app/features/inventory/domain/usecases/return_vehicle_stock.dart';

import 'vehicle_stock_state.dart';

class VehicleStockCubit extends Cubit<VehicleStockState> {
  final GetVehicles _getVehicles;
  final GetVehicleStock _getVehicleStock;
  final GetStockMovements _getStockMovements;
  final LoadVehicleStock _loadVehicleStock;
  final DeductVehicleStock _deductVehicleStock;
  final ReturnVehicleStock _returnVehicleStock;
  final CreateVehicleForCurrentRep _createVehicleForCurrentRep;

  VehicleStockCubit({
    required GetVehicles getVehicles,
    required GetVehicleStock getVehicleStock,
    required GetStockMovements getStockMovements,
    required LoadVehicleStock loadVehicleStock,
    required DeductVehicleStock deductVehicleStock,
    required ReturnVehicleStock returnVehicleStock,
    required CreateVehicleForCurrentRep createVehicleForCurrentRep,
  })  : _getVehicles = getVehicles,
        _getVehicleStock = getVehicleStock,
        _getStockMovements = getStockMovements,
        _loadVehicleStock = loadVehicleStock,
        _deductVehicleStock = deductVehicleStock,
        _returnVehicleStock = returnVehicleStock,
        _createVehicleForCurrentRep = createVehicleForCurrentRep,
        super(const VehicleStockState());

  Future<void> loadVehicles() async {
    if (isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loading,
      clearError: true,
    ));

    try {
      final vehicles = await _getVehicles();

      if (isClosed) return;

      final currentId = state.selectedVehicleId;
      final currentExists = currentId != null &&
          vehicles.any((vehicle) => vehicle.id == currentId);

      final selectedId = currentExists
          ? currentId
          : vehicles.isNotEmpty
              ? vehicles.first.id
              : null;

      if (selectedId == null) {
        emit(state.copyWith(
          status: VehicleStockStatus.loaded,
          vehicles: vehicles,
          clearSelectedVehicle: true,
          vehicleStock: const [],
          movements: const [],
        ));
        return;
      }

      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicles: vehicles,
        selectedVehicleId: selectedId,
        clearError: true,
      ));

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> selectVehicle(String vehicleId) async {
    if (isClosed) return;

    emit(state.copyWith(
      selectedVehicleId: vehicleId,
      status: VehicleStockStatus.loadingStock,
      clearError: true,
      clearSuccess: true,
      vehicleStock: const [],
      movements: const [],
    ));

    await loadSelectedVehicleData();
  }

  Future<void> createVehicle({
    required String plateNumber,
    required String driverName,
  }) async {
    final plate = plateNumber.trim();
    final driver = driverName.trim();
    if (plate.isEmpty || driver.isEmpty) {
      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: 'ط£ط¯ط®ظ„ ط±ظ‚ظ… ط§ظ„ط¹ط±ط¨ظٹط© ظˆط§ط³ظ… ط§ظ„ط³ط§ط¦ظ‚',
      ));
      return;
    }

    emit(state.copyWith(
      status: VehicleStockStatus.loadingAction,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      final vehicle = await _createVehicleForCurrentRep(
        plateNumber: plate,
        driverName: driver,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicles: [vehicle],
        selectedVehicleId: vehicle.id,
        vehicleStock: const [],
        movements: const [],
        successMessage: 'طھظ… ط¥ظ†ط´ط§ط، ط§ظ„ط¹ط±ط¨ظٹط© ط¨ظ†ط¬ط§ط­',
      ));
      await loadSelectedVehicleData();
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(error).message,
      ));
    }
  }

  Future<void> loadSelectedVehicleData() async {
    final vehicleId = state.selectedVehicleId;

    if (vehicleId == null || isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loadingStock,
      clearError: true,
    ));

    try {
      final List<VehicleStockModel> vehicleStock =
          await _getVehicleStock(vehicleId: vehicleId);

      final List<StockMovementModel> movements =
          await _getStockMovements(vehicleId: vehicleId);

      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.loaded,
        vehicleStock: vehicleStock,
        movements: movements,
      ));
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
    }
  }

  Future<void> loadStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required int minThreshold,
    String? note,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(
      status: VehicleStockStatus.loadingAction,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await _loadVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        minThreshold: minThreshold,
        note: note,
      );

      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.success,
        successMessage: 'طھظ… طھط­ظ…ظٹظ„ ط§ظ„ظ…ط®ط²ظˆظ† ظ„ظ„ط¹ط±ط¨ظٹط© ط¨ظ†ط¬ط§ط­',
      ));

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));
      rethrow;
    }
  }

  Future<void> deductStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    if (isClosed) return;

    try {
      await _deductVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        note: note,
      );

      if (isClosed) return;

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));

      rethrow;
    }
  }

  Future<void> returnStock({
    required String vehicleId,
    required String productId,
    required int quantity,
    required String referenceId,
    String? note,
  }) async {
    if (isClosed) return;

    try {
      await _returnVehicleStock(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        referenceId: referenceId,
        note: note,
      );

      if (isClosed) return;

      await loadSelectedVehicleData();
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(
        status: VehicleStockStatus.error,
        errorMessage: mapErrorToAppException(e).message,
      ));

      rethrow;
    }
  }

  Future<void> refresh() {
    return loadSelectedVehicleData();
  }

  void clearMessages() {
    if (isClosed) return;

    emit(state.copyWith(
      clearError: true,
      clearSuccess: true,
    ));
  }
}


============================================================
FILE: lib/features/inventory/presentation/cubit/vehicle_stock_state.dart
============================================================
import 'package:mivet_app/features/inventory/domain/models/delivery_vehicle_model.dart';
import 'package:mivet_app/features/inventory/domain/models/stock_movement_model.dart';
import 'package:mivet_app/features/inventory/domain/models/vehicle_stock_model.dart';

enum VehicleStockStatus {
  initial,
  loading,
  loaded,
  loadingStock,
  loadingMovements,
  loadingAction,
  success,
  error,
}

class VehicleStockState {
  final VehicleStockStatus status;
  final List<DeliveryVehicleModel> vehicles;
  final String? selectedVehicleId;
  final List<VehicleStockModel> vehicleStock;
  final List<StockMovementModel> movements;
  final String? errorMessage;
  final String? successMessage;

  const VehicleStockState({
    this.status = VehicleStockStatus.initial,
    this.vehicles = const [],
    this.selectedVehicleId,
    this.vehicleStock = const [],
    this.movements = const [],
    this.errorMessage,
    this.successMessage,
  });

  DeliveryVehicleModel? get selectedVehicle {
    if (selectedVehicleId == null) return null;

    for (final vehicle in vehicles) {
      if (vehicle.id == selectedVehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  VehicleStockState copyWith({
    VehicleStockStatus? status,
    List<DeliveryVehicleModel>? vehicles,
    String? selectedVehicleId,
    List<VehicleStockModel>? vehicleStock,
    List<StockMovementModel>? movements,
    String? errorMessage,
    String? successMessage,
    bool clearSelectedVehicle = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VehicleStockState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicleId: clearSelectedVehicle
          ? null
          : selectedVehicleId ?? this.selectedVehicleId,
      vehicleStock: vehicleStock ?? this.vehicleStock,
      movements: movements ?? this.movements,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}


============================================================
FILE: lib/features/vehicle_stock/presentation/widgets/vehicle_stock_tile.dart
============================================================
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../inventory/domain/models/product_model.dart';
// import '../../../inventory/domain/models/vehicle_stock_model.dart';

// class VehicleStockTile extends StatelessWidget {
//   final ProductModel product;
//   final VehicleStockModel stock;
//   final VoidCallback onLoadMore;

//   const VehicleStockTile({
//     super.key,
//     required this.product,
//     required this.stock,
//     required this.onLoadMore,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isOut = stock.quantity == 0;
//     final isLow = !isOut && stock.quantity <= stock.minThreshold;
//     final statusColor = isOut
//         ? context.colors.statusNotReached
//         : isLow
//             ? context.colors.statOrange
//             : context.colors.primary;
//     final progress = stock.minThreshold == 0
//         ? 1.0
//         : (stock.quantity / (stock.minThreshold * 2)).clamp(0.0, 1.0);
//     final daysLeft = product.daysUntilExpiry;

//     return Container(
//       padding: EdgeInsets.all(14.w),
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: context.colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 44.w,
//                 height: 44.w,
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(13.r),
//                 ),
//                 child: Icon(CupertinoIcons.bandage_fill,
//                     color: statusColor, size: 18.sp),
//               ),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(product.name,
//                               style: AppTextStyles.cairoMedium16.copyWith(
//                                   color: context.colors.text, fontSize: 13.sp)),
//                         ),
//                         if (product.isExpired)
//                           _Badge(
//                               label: 'ظ…ظ†طھظ‡ظٹ',
//                               color: context.colors.statusNotReached)
//                         else if (daysLeft != null && daysLeft <= 30)
//                           _Badge(
//                               label: 'طµظ„ط§ط­ظٹط© ظ‚ط±ط¨طھ',
//                               color: context.colors.statOrange),
//                       ],
//                     ),
//                     SizedBox(height: 2.h),
//                     Text(
//                       '${product.category} â€” ${product.unit}',
//                       style: AppTextStyles.almaraiRegular14.copyWith(
//                           color: context.colors.textMuted, fontSize: 10.sp),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text('${stock.quantity}',
//                       style: AppTextStyles.cairoBold18
//                           .copyWith(color: statusColor, fontSize: 16.sp)),
//                   Text('ط§ظ„ط­ط¯ ${stock.minThreshold}',
//                       style: AppTextStyles.almaraiRegular14.copyWith(
//                           color: context.colors.textMuted, fontSize: 9.sp)),
//                 ],
//               ),
//               SizedBox(width: 10.w),
//               Material(
//                 color: context.colors.primary,
//                 borderRadius: BorderRadius.circular(10.r),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(10.r),
//                   onTap: onLoadMore,
//                   child: Padding(
//                     padding: EdgeInsets.all(8.w),
//                     child: Icon(CupertinoIcons.add,
//                         color: Colors.white, size: 14.sp),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 10.h),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(20.r),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 6.h,
//               backgroundColor: context.colors.background,
//               valueColor: AlwaysStoppedAnimation(statusColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Badge extends StatelessWidget {
//   final String label;
//   final Color color;

//   const _Badge({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(right: 6.w),
//       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
//       decoration: BoxDecoration(
//           color: color.withOpacity(0.12),
//           borderRadius: BorderRadius.circular(8.r)),
//       child: Text(label,
//           style: AppTextStyles.cairoMedium16
//               .copyWith(color: color, fontSize: 9.sp)),
//     );
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';

class VehicleStockTile extends StatelessWidget {
  final ProductModel product;
  final VehicleStockModel stock;
  final String categoryName;
  final String unitName;
  final VoidCallback onTap;
  final VoidCallback onLoadMore;

  const VehicleStockTile({
    super.key,
    required this.product,
    required this.stock,
    required this.categoryName,
    required this.unitName,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = stock.quantity == 0;
    final isLow = !isOut && stock.quantity <= stock.minThreshold;
    final statusColor = isOut
        ? context.colors.statusNotReached
        : isLow
            ? context.colors.statOrange
            : context.colors.primary;
    final progress = stock.minThreshold == 0
        ? 1.0
        : (stock.quantity / (stock.minThreshold * 2)).clamp(0.0, 1.0);
    final daysLeft = product.daysUntilExpiry;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(CupertinoIcons.bandage_fill,
                        color: statusColor, size: 18.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(product.name,
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.text,
                                      fontSize: 13.sp)),
                            ),
                            if (product.isExpired)
                              _Badge(
                                  label: 'ظ…ظ†طھظ‡ظٹ',
                                  color: context.colors.statusNotReached)
                            else if (daysLeft != null && daysLeft <= 30)
                              _Badge(
                                  label: 'طµظ„ط§ط­ظٹط© ظ‚ط±ط¨طھ',
                                  color: context.colors.statOrange),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$categoryName â€” $unitName',
                          style: AppTextStyles.almaraiRegular14.copyWith(
                              color: context.colors.textMuted, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${stock.quantity}',
                          style: AppTextStyles.cairoBold18
                              .copyWith(color: statusColor, fontSize: 16.sp)),
                      Text('ط§ظ„ط­ط¯ ${stock.minThreshold}',
                          style: AppTextStyles.almaraiRegular14.copyWith(
                              color: context.colors.textMuted, fontSize: 9.sp)),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  Material(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: onLoadMore,
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(CupertinoIcons.add,
                            color: Colors.white, size: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6.h,
                  backgroundColor: context.colors.background,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8.r)),
      child: Text(label,
          style: AppTextStyles.cairoMedium16
              .copyWith(color: color, fontSize: 9.sp)),
    );
  }
}


============================================================
FILE: lib/features/vehicle_stock/presentation/widgets/existing_product_picker_sheet.dart
============================================================
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

import '../../../inventory/domain/models/product_catalog.dart';

class ExistingProductPickerSheet extends StatefulWidget {
  final Future<List<ProductModel>> Function() loadProducts;
  final ProductCatalog catalog;

  const ExistingProductPickerSheet({
    super.key,
    required this.loadProducts,
    this.catalog = ProductCatalog.empty,
  });

  @override
  State<ExistingProductPickerSheet> createState() =>
      _ExistingProductPickerSheetState();
}

class _ExistingProductPickerSheetState
    extends State<ExistingProductPickerSheet> {
  final _search = TextEditingController();
  List<ProductModel>? _products;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.loadProducts().then((products) {
      if (mounted) setState(() => _products = products);
    }).catchError((Object error) {
      if (mounted) setState(() => _error = error.toString());
    });
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    if (products == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final filtered = products
        .where((product) =>
            query.isEmpty || product.name.toLowerCase().contains(query))
        .toList();
    return SafeArea(
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        child: Column(
          children: [
            Text('ط§ط®طھظٹط§ط± طµظ†ظپ ظ…ظˆط¬ظˆط¯',
                style: AppTextStyles.cairoBold18.copyWith(fontSize: 16.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: _search,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'ط§ط¨ط­ط« ط¨ط§ط³ظ… ط§ظ„طµظ†ظپ',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            '${widget.catalog.categoryName(product.category)} â€” '
                            '${widget.catalog.unitName(product.unit)}',
                          ),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


============================================================
FILE: lib/features/vehicle_stock/presentation/widgets/category_filter_tab.dart
============================================================
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class CategoryFilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryFilterTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: selected ? Colors.transparent : context.colors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: selected ? Colors.white : context.colors.text,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      );
}


============================================================
FILE: lib/core/di/service_locator.dart
============================================================
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/customer_account/data/datasources/customer_account_remote_data_source.dart';
import '../../features/customer_account/data/repositories/customer_account_repository.dart';
import '../../features/customer_account/data/repositories/customer_account_repository_impl.dart';
import '../../features/customer_account/domain/usecases/create_sales_return.dart';
import '../../features/customer_account/domain/usecases/get_customer_ledger.dart';
import '../../features/customer_account/domain/usecases/get_invoice_returned_quantities.dart';
import '../../features/customer_account/domain/usecases/record_customer_account_payment.dart';
import '../../features/customer_account/domain/usecases/record_customer_payment.dart';
import '../../features/customer_account/presentation/cubit/customer_account_cubit.dart';
import '../../features/daily_report/domain/daily_report_repository.dart';
import '../../features/home/data/expense_repository.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/inventory/data/datasources/vehicle_stock_remote_data_source.dart';
import '../../features/inventory/data/products_repository.dart';
import '../../features/inventory/data/repositories/vehicle_stock_repository_impl.dart';
import '../../features/inventory/domain/repositories/vehicle_stock_repository.dart';
import '../../features/inventory/domain/usecases/create_vehicle_for_current_rep.dart';
import '../../features/inventory/domain/usecases/deduct_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/get_stock_movements.dart';
import '../../features/inventory/domain/usecases/get_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/get_vehicles.dart';
import '../../features/inventory/domain/usecases/load_vehicle_stock.dart';
import '../../features/inventory/domain/usecases/return_vehicle_stock.dart';
import '../../features/inventory/presentation/cubit/vehicle_stock_cubit.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepository(Supabase.instance.client),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepository(Supabase.instance.client),
  );

  sl.registerLazySingleton<DailyReportRepository>(
    () => DailyReportRepository(Supabase.instance.client),
  );

  sl.registerLazySingleton<CustomerAccountRemoteDataSource>(
    () => CustomerAccountRemoteDataSource(Supabase.instance.client),
  );

  sl.registerLazySingleton<CustomerAccountRepository>(
    () => CustomerAccountRepositoryImpl(sl()),
  );

  sl.registerFactory<GetCustomerLedger>(
    () => GetCustomerLedger(sl()),
  );

  sl.registerFactory<RecordCustomerPayment>(
    () => RecordCustomerPayment(sl()),
  );

  sl.registerFactory<RecordCustomerAccountPayment>(
    () => RecordCustomerAccountPayment(sl()),
  );

  sl.registerFactory<CreateSalesReturn>(
    () => CreateSalesReturn(sl()),
  );

  sl.registerFactory<GetInvoiceReturnedQuantities>(
    () => GetInvoiceReturnedQuantities(sl()),
  );

  sl.registerFactory<CustomerAccountCubit>(
    () => CustomerAccountCubit(
      getCustomerLedger: sl(),
      recordCustomerAccountPayment: sl(),
      createSalesReturn: sl(),
      getInvoiceReturnedQuantities: sl(),
    ),
  );

  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepository.instance,
  );

  sl.registerLazySingleton<VehicleStockRemoteDataSource>(
    () => VehicleStockRemoteDataSource(Supabase.instance.client),
  );

  sl.registerLazySingleton<VehicleStockRepository>(
    () => VehicleStockRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerFactory<GetVehicles>(
    () => GetVehicles(sl()),
  );

  sl.registerFactory<CreateVehicleForCurrentRep>(
    () => CreateVehicleForCurrentRep(sl()),
  );

  sl.registerFactory<GetVehicleStock>(
    () => GetVehicleStock(sl()),
  );

  sl.registerFactory<GetStockMovements>(
    () => GetStockMovements(sl()),
  );

  sl.registerFactory<LoadVehicleStock>(
    () => LoadVehicleStock(sl()),
  );

  sl.registerFactory<DeductVehicleStock>(
    () => DeductVehicleStock(sl()),
  );

  sl.registerFactory<ReturnVehicleStock>(
    () => ReturnVehicleStock(sl()),
  );

  sl.registerLazySingleton<VehicleStockCubit>(
    () => VehicleStockCubit(
      getVehicles: sl(),
      getVehicleStock: sl(),
      getStockMovements: sl(),
      loadVehicleStock: sl(),
      deductVehicleStock: sl(),
      returnVehicleStock: sl(),
      createVehicleForCurrentRep: sl(),
    ),
  );
}


