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
              title: Text(isCategory ? 'إنشاء تصنيف' : 'إضافة وحدة قياس'),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                      labelText: isCategory ? 'اسم التصنيف' : 'اسم الوحدة')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, controller.text),
                    child: const Text('إنشاء'))
              ],
            ));
            
    Future.delayed(const Duration(milliseconds: 300), () => controller.dispose());
    
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
          context, Exception('برجاء إدخال بيانات الصنف والكمية بشكل صحيح'));
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
                  Text(_isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد',
                      style: AppTextStyles.cairoBold18.copyWith(
                          color: context.colors.text, fontSize: 16.sp)),
                  SizedBox(height: 16.h),
                  ProductImagePicker(
                      imagePath: _imagePath,
                      onChanged: (value) => setState(() => _imagePath = value)),
                  SizedBox(height: 16.h),
                  _field('اسم الصنف', _name, text: true),
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(
                        child: _field('سعر التجزئة', _retail, decimal: true)),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: _field('سعر الجملة', _wholesale, decimal: true))
                  ]),
                  SizedBox(height: 12.h),
                  _field('الحد الأدنى للمخزون', _threshold),
                  if (widget.initialVehicleQuantity != null) ...[
                    SizedBox(height: 12.h),
                    _field('الكمية الأولية للعربية', _quantity)
                  ],
                  SizedBox(height: 12.h),
                  _dropdown(
                      'التصنيف',
                      _categories,
                      _category,
                      (value) => setState(() => _category = value),
                      () => _createCatalog(true),
                      'إضافة تصنيف'),
                  SizedBox(height: 12.h),
                  _dropdown(
                      'وحدة القياس',
                      _units,
                      _unit,
                      (value) => setState(() => _unit = value),
                      () => _createCatalog(false),
                      'إضافة وحدة قياس'),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                      onPressed: _pickExpiryDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_expiryDate == null
                          ? 'تاريخ الصلاحية (اختياري)'
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
                          : Text(_isEditing ? 'حفظ التعديلات' : 'حفظ الصنف')),
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