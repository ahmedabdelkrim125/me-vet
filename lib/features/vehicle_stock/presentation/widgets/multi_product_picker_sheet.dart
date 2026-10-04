import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

import '../../../inventory/domain/models/product_catalog.dart';

class ProductQuantityEntry {
  final ProductModel product;
  final int quantity;

  const ProductQuantityEntry({required this.product, required this.quantity});
}

class MultiProductPickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  final ProductCatalog catalog;
  final Map<String, int> currentQuantities;

  const MultiProductPickerSheet({
    super.key,
    required this.products,
    this.catalog = ProductCatalog.empty,
    this.currentQuantities = const {},
  });

  @override
  State<MultiProductPickerSheet> createState() =>
      _MultiProductPickerSheetState();
}

class _MultiProductPickerSheetState extends State<MultiProductPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, ProductModel> _selected = {};
  late final List<ProductModel> _products;
  String? _justSelectedId;

  @override
  void initState() {
    super.initState();
    _products = [...widget.products]
      ..sort((a, b) => a.name.compareTo(b.name));
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle(ProductModel product) {
    setState(() {
      if (_selected.containsKey(product.id)) {
        _selected.remove(product.id);
        _quantityControllers.remove(product.id)?.dispose();
        return;
      }
      _selected[product.id] = product;
      _quantityControllers[product.id] = TextEditingController();
      _justSelectedId = product.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _justSelectedId = null;
    });
  }

  int _quantityOf(String productId) =>
      int.tryParse(_quantityControllers[productId]?.text.trim() ?? '') ?? 0;

  int get _missingQuantityCount =>
      _selected.keys.where((id) => _quantityOf(id) <= 0).length;

  bool get _canSubmit => _selected.isNotEmpty && _missingQuantityCount == 0;

  void _submit() {
    if (!_canSubmit) return;
    final entries = _selected.values
        .map((product) => ProductQuantityEntry(
              product: product,
              quantity: _quantityOf(product.id),
            ))
        .toList();
    Navigator.pop(context, entries);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: _buildContent(context, _products),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ProductModel> products) {
    final colors = context.colors;
    final query = _search.text.trim().toLowerCase();
    final filtered = products
        .where((product) =>
            query.isEmpty || product.name.toLowerCase().contains(query))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'اختيار عدة أصناف',
            textAlign: TextAlign.center,
            style: AppTextStyles.cairoBold18
                .copyWith(color: colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'أصناف عربيتك بس — علّم على الأصناف واكتب كمية كل صنف، والكمية بتتضاف على الموجود',
            textAlign: TextAlign.center,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 11.sp),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _search,
            textAlign: TextAlign.right,
            style: AppTextStyles.almaraiRegular14.copyWith(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث باسم الصنف',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Center(
                      child: Text(
                        'لا توجد أصناف مطابقة',
                        style: AppTextStyles.almaraiRegular14
                            .copyWith(color: colors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildRow(context, filtered[index]),
                  ),
          ),
          SizedBox(height: 10.h),
          if (_selected.isNotEmpty && _missingQuantityCount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'اكتب كمية لكل الأصناف المختارة ($_missingQuantityCount ناقص)',
                textAlign: TextAlign.center,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.statusNotReached, fontSize: 11.sp),
              ),
            ),
          SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                _selected.isEmpty
                    ? 'اختر أصناف أولاً'
                    : 'إضافة ${_selected.length} للعربية',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: _canSubmit ? Colors.white : colors.textMuted,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ProductModel product) {
    final colors = context.colors;
    final isSelected = _selected.containsKey(product.id);
    final current = widget.currentQuantities[product.id];
    final subtitle = [
      widget.catalog.categoryName(product.category),
      if (current != null) 'في العربية: $current',
    ].join(' • ');

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? colors.primary.withOpacity(0.08) : colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? colors.primary : colors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _toggle(product),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: colors.primary,
                onChanged: (_) => _toggle(product),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.text, fontSize: 13.sp),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTextStyles.almaraiRegular14.copyWith(
                            color: colors.textMuted, fontSize: 10.sp),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                SizedBox(
                  width: 78.w,
                  child: TextField(
                    controller: _quantityControllers[product.id],
                    autofocus: _justSelectedId == product.id,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 13.sp),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: colors.background,
                      hintText: 'الكمية',
                      hintStyle: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 11.sp),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 8.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide:
                            BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}