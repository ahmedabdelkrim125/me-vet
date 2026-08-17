// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../domain/mock_inventory_repository.dart';
// import '../../domain/models/product_category.dart';
// import '../../domain/models/product_model.dart';
// import '../../domain/models/product_unit.dart';
// import 'product_image_picker.dart';

// Future<void> showAddProductSheet(BuildContext context,
//     {ProductModel? productToEdit}) {
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => _AddProductSheet(productToEdit: productToEdit),
//   );
// }

// class _AddProductSheet extends StatefulWidget {
//   final ProductModel? productToEdit;

//   const _AddProductSheet({this.productToEdit});

//   @override
//   State<_AddProductSheet> createState() => _AddProductSheetState();
// }

// class _AddProductSheetState extends State<_AddProductSheet> {
//   late final TextEditingController _nameController;
//   late final TextEditingController _priceController;
//   late final TextEditingController _thresholdController;
//   late ProductCategory _category;
//   late ProductUnit _unit;
//   String? _imagePath;

//   bool get _isEditing => widget.productToEdit != null;

//   @override
//   void initState() {
//     super.initState();
//     final product = widget.productToEdit;
//     _nameController = TextEditingController(text: product?.name ?? '');
//     _priceController = TextEditingController(
//         text: product != null ? product.basePrice.toStringAsFixed(0) : '');
//     _thresholdController =
//         TextEditingController(text: '${product?.minStockThreshold ?? 5}');
//     _category = product?.category ?? ProductCategory.poultry;
//     _unit = product?.unit ?? ProductUnit.piece;
//     _imagePath = product?.imagePath;
//   }

//   Future<void> _submit() async {
//     if (_nameController.text.trim().isEmpty) return;
//     final price = double.tryParse(_priceController.text) ?? 0;
//     final threshold = int.tryParse(_thresholdController.text) ?? 5;

//     if (_isEditing) {
//       await MockInventoryRepository.instance.updateProduct(
//         widget.productToEdit!.copyWith(
//           name: _nameController.text.trim(),
//           imagePath: _imagePath,
//           category: _category,
//           unit: _unit,
//           basePrice: price,
//           minStockThreshold: threshold,
//         ),
//       );
//     } else {
//       await MockInventoryRepository.instance.addProduct(
//         ProductModel(
//           id: 'P-${DateTime.now().millisecondsSinceEpoch}',
//           name: _nameController.text.trim(),
//           imagePath: _imagePath,
//           category: _category,
//           unit: _unit,
//           basePrice: price,
//           minStockThreshold: threshold,
//           createdAt: DateTime.now(),
//         ),
//       );
//     }

//     if (mounted) Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.8,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       expand: false,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: BoxDecoration(
//             color: context.colors.background,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
//           ),
//           padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
//           child: ListView(
//             controller: scrollController,
//             children: [
//               Center(
//                 child: Container(
//                   width: 42.w,
//                   height: 4.h,
//                   decoration: BoxDecoration(
//                       color: context.colors.border,
//                       borderRadius: BorderRadius.circular(10.r)),
//                 ),
//               ),
//               SizedBox(height: 14.h),
//               Text(_isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد',
//                   style: AppTextStyles.cairoBold18
//                       .copyWith(color: context.colors.text, fontSize: 16.sp)),
//               SizedBox(height: 18.h),
//               ProductImagePicker(
//                 imagePath: _imagePath,
//                 onChanged: (path) => setState(() => _imagePath = path),
//               ),
//               SizedBox(height: 18.h),
//               _Field(label: 'اسم الصنف', controller: _nameController),
//               SizedBox(height: 14.h),
//               _Field(
//                   label: 'السعر الأساسي',
//                   controller: _priceController,
//                   keyboardType: TextInputType.number),
//               SizedBox(height: 14.h),
//               _Field(
//                   label: 'الحد الأدنى العام',
//                   controller: _thresholdController,
//                   keyboardType: TextInputType.number),
//               SizedBox(height: 14.h),
//               Text('التصنيف البيطري',
//                   style: AppTextStyles.almaraiRegular14.copyWith(
//                       color: context.colors.textMuted, fontSize: 11.sp)),
//               SizedBox(height: 8.h),
//               Wrap(
//                 spacing: 8.w,
//                 runSpacing: 8.h,
//                 children: [
//                   for (final category in ProductCategory.values)
//                     _SelectChip(
//                       label: category.label,
//                       isSelected: _category == category,
//                       onTap: () => setState(() => _category = category),
//                     ),
//                 ],
//               ),
//               SizedBox(height: 14.h),
//               Text('وحدة القياس',
//                   style: AppTextStyles.almaraiRegular14.copyWith(
//                       color: context.colors.textMuted, fontSize: 11.sp)),
//               SizedBox(height: 8.h),
//               Wrap(
//                 spacing: 8.w,
//                 runSpacing: 8.h,
//                 children: [
//                   for (final unit in ProductUnit.values)
//                     _SelectChip(
//                       label: unit.label,
//                       isSelected: _unit == unit,
//                       onTap: () => setState(() => _unit = unit),
//                     ),
//                 ],
//               ),
//               SizedBox(height: 22.h),
//               Material(
//                 color: context.colors.primary,
//                 borderRadius: BorderRadius.circular(14.r),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(14.r),
//                   onTap: _submit,
//                   child: Container(
//                     alignment: Alignment.center,
//                     padding: EdgeInsets.symmetric(vertical: 15.h),
//                     child: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ الصنف',
//                         style: AppTextStyles.cairoMedium16
//                             .copyWith(color: Colors.white, fontSize: 14.sp)),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _Field extends StatelessWidget {
//   final String label;
//   final TextEditingController controller;
//   final TextInputType? keyboardType;

//   const _Field(
//       {required this.label, required this.controller, this.keyboardType});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label,
//             style: AppTextStyles.almaraiRegular14
//                 .copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
//         SizedBox(height: 6.h),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           textAlign: TextAlign.right,
//           style:
//               AppTextStyles.cairoMedium16.copyWith(color: context.colors.text),
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: context.colors.surface,
//             contentPadding:
//                 EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: BorderSide(color: context.colors.border)),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: BorderSide(color: context.colors.border)),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: BorderSide(color: context.colors.primary)),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SelectChip extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _SelectChip(
//       {required this.label, required this.isSelected, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? context.colors.primary.withOpacity(0.12)
//               : context.colors.surface,
//           borderRadius: BorderRadius.circular(10.r),
//           border: Border.all(
//               color:
//                   isSelected ? context.colors.primary : context.colors.border),
//         ),
//         child: Text(
//           label,
//           style: AppTextStyles.cairoMedium16.copyWith(
//             color:
//                 isSelected ? context.colors.primary : context.colors.textMuted,
//             fontSize: 12.sp,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/mock_inventory_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/product_unit.dart';
import 'product_image_picker.dart';

Future<void> showAddProductSheet(BuildContext context, {ProductModel? productToEdit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddProductSheet(productToEdit: productToEdit),
  );
}

class _AddProductSheet extends StatefulWidget {
  final ProductModel? productToEdit;

  const _AddProductSheet({this.productToEdit});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _warehouseQtyController;
  late ProductCategory _category;
  late ProductUnit _unit;
  String? _imagePath;
  DateTime? _expiryDate;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
        text: product != null ? product.basePrice.toStringAsFixed(0) : '');
    _thresholdController = TextEditingController(text: '${product?.minStockThreshold ?? 5}');
    _warehouseQtyController = TextEditingController(text: '0');
    _category = product?.category ?? ProductCategory.poultry;
    _unit = product?.unit ?? ProductUnit.piece;
    _imagePath = product?.imagePath;
    _expiryDate = product?.expiryDate;
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    final price = double.tryParse(_priceController.text) ?? 0;
    final threshold = int.tryParse(_thresholdController.text) ?? 5;

    if (_isEditing) {
      await MockInventoryRepository.instance.updateProduct(
        widget.productToEdit!.copyWith(
          name: _nameController.text.trim(),
          imagePath: _imagePath,
          category: _category,
          unit: _unit,
          basePrice: price,
          minStockThreshold: threshold,
          expiryDate: _expiryDate,
        ),
      );
    } else {
      final warehouseQty = int.tryParse(_warehouseQtyController.text) ?? 0;
      await MockInventoryRepository.instance.addProduct(
        ProductModel(
          id: 'P-${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          imagePath: _imagePath,
          category: _category,
          unit: _unit,
          basePrice: price,
          minStockThreshold: threshold,
          expiryDate: _expiryDate,
          createdAt: DateTime.now(),
        ),
        initialWarehouseQuantity: warehouseQty,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                      color: context.colors.border, borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Text(_isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد',
                  style: AppTextStyles.cairoBold18.copyWith(color: context.colors.text, fontSize: 16.sp)),
              SizedBox(height: 18.h),
              ProductImagePicker(
                imagePath: _imagePath,
                onChanged: (path) => setState(() => _imagePath = path),
              ),
              SizedBox(height: 18.h),
              _Field(label: 'اسم الصنف', controller: _nameController),
              SizedBox(height: 14.h),
              _Field(label: 'السعر الأساسي', controller: _priceController, keyboardType: TextInputType.number),
              SizedBox(height: 14.h),
              _Field(label: 'الحد الأدنى العام', controller: _thresholdController, keyboardType: TextInputType.number),
              if (!_isEditing) ...[
                SizedBox(height: 14.h),
                _Field(
                  label: 'الكمية الابتدائية في المخزن الرئيسي',
                  controller: _warehouseQtyController,
                  keyboardType: TextInputType.number,
                ),
              ],
              SizedBox(height: 14.h),
              Text('تاريخ الصلاحية (اختياري)',
                  style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickExpiryDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16.sp, color: context.colors.textMuted),
                            SizedBox(width: 10.w),
                            Text(
                              _expiryDate == null
                                  ? 'اختر التاريخ'
                                  : DateFormat('yyyy/MM/dd').format(_expiryDate!),
                              style: AppTextStyles.cairoMedium16.copyWith(color: context.colors.text, fontSize: 13.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_expiryDate != null) ...[
                    SizedBox(width: 8.w),
                    Material(
                      color: context.colors.statusNotReached.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => setState(() => _expiryDate = null),
                        child: Padding(
                          padding: EdgeInsets.all(13.w),
                          child: Icon(Icons.close_rounded, size: 16.sp, color: context.colors.statusNotReached),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14.h),
              Text('التصنيف البيطري',
                  style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
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
                  style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
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
                    child: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ الصنف',
                        style: AppTextStyles.cairoMedium16.copyWith(color: Colors.white, fontSize: 14.sp)),
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

  const _Field({required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.almaraiRegular14.copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          style: AppTextStyles.cairoMedium16.copyWith(color: context.colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.colors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.colors.primary)),
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

  const _SelectChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withOpacity(0.12) : context.colors.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? context.colors.primary : context.colors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.cairoMedium16.copyWith(
            color: isSelected ? context.colors.primary : context.colors.textMuted,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}