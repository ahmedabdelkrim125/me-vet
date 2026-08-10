import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/mock_inventory_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/product_unit.dart';

Future<void> showAddProductSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AddProductSheet(),
  );
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _thresholdController = TextEditingController(text: '5');
  ProductCategory _category = ProductCategory.poultry;
  ProductUnit _unit = ProductUnit.piece;

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    final price = double.tryParse(_priceController.text) ?? 0;
    final threshold = int.tryParse(_thresholdController.text) ?? 5;

    await MockInventoryRepository.instance.addProduct(
      ProductModel(
        id: 'P-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _category,
        unit: _unit,
        basePrice: price,
        minStockThreshold: threshold,
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              SizedBox(height: 14.h),
              Text('إضافة صنف جديد',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.text, fontSize: 16.sp)),
              SizedBox(height: 18.h),
              _Field(label: 'اسم الصنف', controller: _nameController),
              SizedBox(height: 14.h),
              _Field(
                  label: 'السعر الأساسي',
                  controller: _priceController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 14.h),
              _Field(
                  label: 'الحد الأدنى العام',
                  controller: _thresholdController,
                  keyboardType: TextInputType.number),
              SizedBox(height: 14.h),
              Text('التصنيف البيطري',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 11.sp)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final category in ProductCategory.values)
                    _SelectChip(
                      label: category.label,
                      isSelected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              SizedBox(height: 14.h),
              Text('وحدة القياس',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 11.sp)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final unit in ProductUnit.values)
                    _SelectChip(
                      label: unit.label,
                      isSelected: _unit == unit,
                      onTap: () => setState(() => _unit = unit),
                    ),
                ],
              ),
              SizedBox(height: 22.h),
              Material(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: _submit,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: Text('حفظ الصنف',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: Colors.white, fontSize: 14.sp)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field(
      {required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          style:
              AppTextStyles.cairoMedium16.copyWith(color: context.colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surface,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.colors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.colors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.colors.primary)),
          ),
        ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withOpacity(0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color:
                  isSelected ? context.colors.primary : context.colors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.cairoMedium16.copyWith(
            color:
                isSelected ? context.colors.primary : context.colors.textMuted,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
