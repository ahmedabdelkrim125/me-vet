import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../data/products_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/product_detail_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<ProductModel> _products = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  ProductCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await ProductsRepository.instance.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<ProductModel> get _filtered {
    return _products.where((product) {
      final matchesQuery = _query.isEmpty ||
          product.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _categoryFilter == null || product.category == _categoryFilter;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _openAddProduct() async {
    await showAddProductSheet(context);
    _loadProducts();
  }

  Future<void> _openProductDetail(ProductModel product) async {
    await showProductDetailSheet(context, product);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(20.w),
                      children: [
                        SizedBox(height: 120.h),
                        Icon(
                          Icons.error_outline_rounded,
                          size: 52.sp,
                          color: context.colors.textMuted,
                        ),
                        SizedBox(height: 16.h),
                        Center(
                          child: Text(
                            _error!,
                            style: AppTextStyles.cairoMedium16.copyWith(
                              color: context.colors.textMuted,
                              fontSize: 13.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المنتجات',
                  style: AppTextStyles.cairoBold18.copyWith(
                    color: context.colors.text,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Material(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _openAddProduct,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'إضافة صنف',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '${_products.length} صنف مسجل',
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: context.colors.textMuted,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 14.h),
          InventorySearchBar(
            onChanged: (value) {
              setState(() => _query = value);
            },
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 36.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'الكل',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                for (final category in ProductCategory.values)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: _CategoryChip(
                      label: category.label,
                      selected: _categoryFilter == category,
                      onTap: () => setState(() => _categoryFilter = category),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 60.h),
              child: Center(
                child: Text(
                  _products.isEmpty
                      ? 'لا توجد أصناف مسجلة بعد'
                      : 'لا توجد أصناف مطابقة للبحث',
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            )
          else
            for (final product in filtered)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ProductTile(
                  product: product,
                  onTap: () => _openProductDetail(product),
                ),
              ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colors.primary
          : context.colors.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? Colors.transparent : context.colors.border,
            ),
          ),
          alignment: Alignment.center,
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
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.network(product.imagePath!, fit: BoxFit.cover)
                    : Icon(
                        Icons.medication_liquid_outlined,
                        color: context.colors.primary,
                        size: 22.sp,
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.cairoMedium16.copyWith(
                        color: context.colors.text,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      product.category.label,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: context.colors.textMuted,
                        fontSize: 10.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${product.retailPrice.toStringAsFixed(0)} ج.م',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: context.colors.text,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}