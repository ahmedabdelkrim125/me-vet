import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/inventory/domain/models/product_model.dart';

class HistoricalProductPickerSheet extends StatefulWidget {
  final List<ProductModel> catalog;

  const HistoricalProductPickerSheet({super.key, required this.catalog});

  @override
  State<HistoricalProductPickerSheet> createState() =>
      _HistoricalProductPickerSheetState();
}

class _HistoricalProductPickerSheetState
    extends State<HistoricalProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        final colors = context.colors;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    final query = value.text.trim();
                    final visible = query.isEmpty
                        ? widget.catalog
                        : widget.catalog
                            .where((p) => p.name.contains(query))
                            .toList();

                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final product = visible[index];
                        return ListTile(
                          title: Text(
                            product.name,
                            style: AppTextStyles.cairoMedium16
                                .copyWith(fontSize: 13.sp),
                          ),
                          trailing: Text(
                            '${product.basePrice.toStringAsFixed(0)} ج.م',
                            style: TextStyle(color: colors.text),
                          ),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
