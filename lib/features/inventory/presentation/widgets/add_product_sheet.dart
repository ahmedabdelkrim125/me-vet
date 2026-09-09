import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../data/products_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/product_unit.dart';
import 'product_image_picker.dart';

Future<void> showAddProductSheet(
  BuildContext context, {
  ProductModel? productToEdit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddProductSheet(
      productToEdit: productToEdit,
    ),
  );
}

class _AddProductSheet extends StatefulWidget {
  final ProductModel? productToEdit;

  const _AddProductSheet({
    this.productToEdit,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _retailPriceController;
  late final TextEditingController _wholesalePriceController;
  late final TextEditingController _thresholdController;

  late ProductCategory _category;
  late ProductUnit _unit;

  String? _imagePath;
  DateTime? _expiryDate;
  bool _saving = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();

    final product = widget.productToEdit;

    _nameController = TextEditingController(
      text: product?.name ?? '',
    );

    _retailPriceController = TextEditingController(
      text: product != null ? product.retailPrice.toStringAsFixed(2) : '',
    );

    _wholesalePriceController = TextEditingController(
      text: product != null ? product.wholesalePrice.toStringAsFixed(2) : '',
    );

    _thresholdController = TextEditingController(
      text: '${product?.minStockThreshold ?? 5}',
    );

    _category = product?.category ?? ProductCategory.poultry;
    _unit = product?.unit ?? ProductUnit.piece;
    _imagePath = product?.imagePath;
    _expiryDate = product?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final retailPrice = double.tryParse(_retailPriceController.text.trim());
    final wholesalePrice =
        double.tryParse(_wholesalePriceController.text.trim());
    final threshold = int.tryParse(_thresholdController.text.trim());

    if (name.isEmpty ||
        retailPrice == null ||
        wholesalePrice == null ||
        threshold == null ||
        retailPrice < 0 ||
        wholesalePrice < 0 ||
        threshold < 0) {
      showAppError(
        context,
        Exception('برجاء إدخال بيانات الصنف بشكل صحيح'),
      );
      return;
    }

    if (wholesalePrice > retailPrice) {
      showAppError(
        context,
        Exception('سعر الجملة لا يمكن أن يكون أكبر من سعر التجزئة'),
      );
      return;
    }

    setState(() => _saving = true);

    String? uploadedImagePath;

    try {
      var imagePath = _imagePath;

      if (imagePath != null && !imagePath.startsWith('http')) {
        uploadedImagePath =
            await ProductsRepository.instance.uploadProductImage(imagePath);
        imagePath = uploadedImagePath;
      }

      if (_isEditing) {
        final oldPath = widget.productToEdit!.imagePath;

        await ProductsRepository.instance.updateProduct(
          widget.productToEdit!.copyWith(
            name: name,
            imagePath: imagePath,
            category: _category,
            unit: _unit,
            retailPrice: retailPrice,
            wholesalePrice: wholesalePrice,
            minStockThreshold: threshold,
            expiryDate: _expiryDate,
          ),
        );

        if (oldPath != null && oldPath != imagePath) {
          await ProductsRepository.instance.deleteProductImage(oldPath);
        }
      } else {
        await ProductsRepository.instance.createProduct(
          name: name,
          category: _category,
          unit: _unit,
          retailPrice: retailPrice,
          wholesalePrice: wholesalePrice,
          minStockThreshold: threshold,
          imagePath: imagePath,
          expiryDate: _expiryDate,
        );
      }
    } catch (error) {
      if (uploadedImagePath != null && !_isEditing) {
        try {
          await ProductsRepository.instance
              .deleteProductImage(uploadedImagePath);
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _saving = false);
        showAppError(context, error);
      }

      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24.r),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20.w,
            14.h,
            20.w,
            16.h,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                _isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: context.colors.text,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 18.h),
              ProductImagePicker(
                imagePath: _imagePath,
                onChanged: (path) {
                  setState(() => _imagePath = path);
                },
              ),
              SizedBox(height: 18.h),
              _Field(
                label: 'اسم الصنف',
                controller: _nameController,
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'سعر التجزئة',
                      controller: _retailPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _Field(
                      label: 'سعر الجملة',
                      controller: _wholesalePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _Field(
                label: 'الحد الأدنى العام',
                controller: _thresholdController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 14.h),
              Text(
                'تاريخ الصلاحية',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: context.colors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 6.h),
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 13.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18.r,
                        color: context.colors.textMuted,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _expiryDate == null
                              ? 'بدون تاريخ صلاحية'
                              : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.text,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      if (_expiryDate != null)
                        IconButton(
                          onPressed: () {
                            setState(() => _expiryDate = null);
                          },
                          icon: Icon(
                            Icons.close,
                            size: 18.r,
                            color: context.colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              _SelectionSection<ProductCategory>(
                title: 'التصنيف البيطري',
                values: ProductCategory.values,
                selected: _category,
                labelBuilder: (value) => value.label,
                onSelected: (value) {
                  setState(() => _category = value);
                },
              ),
              SizedBox(height: 14.h),
              _SelectionSection<ProductUnit>(
                title: 'وحدة القياس',
                values: ProductUnit.values,
                selected: _unit,
                labelBuilder: (value) => value.label,
                onSelected: (value) {
                  setState(() => _unit = value);
                },
              ),
              SizedBox(height: 22.h),
              Material(
                color: _saving
                    ? context.colors.primary.withOpacity(0.5)
                    : context.colors.primary,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: _saving ? null : _submit,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: _saving
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'حفظ التعديلات' : 'حفظ الصنف',
                            style: AppTextStyles.cairoMedium16.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
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

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: context.colors.textMuted,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          style: AppTextStyles.cairoMedium16.copyWith(
            color: context.colors.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.colors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.colors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionSection<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _SelectionSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: context.colors.textMuted,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final value in values)
              GestureDetector(
                onTap: () => onSelected(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: selected == value
                        ? context.colors.primary.withOpacity(0.12)
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected == value
                          ? context.colors.primary
                          : context.colors.border,
                    ),
                  ),
                  child: Text(
                    labelBuilder(value),
                    style: AppTextStyles.cairoMedium16.copyWith(
                      color: selected == value
                          ? context.colors.primary
                          : context.colors.textMuted,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
