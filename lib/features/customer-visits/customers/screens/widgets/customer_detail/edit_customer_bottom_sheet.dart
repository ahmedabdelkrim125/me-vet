import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/location/location_service.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import 'customer_form_widgets.dart';

Future<CustomerModel?> showEditCustomerBottomSheet(
  BuildContext context, {
  required CustomerModel customer,
}) {
  return showModalBottomSheet<CustomerModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EditCustomerBottomSheet(customer: customer),
  );
}

class _EditCustomerBottomSheet extends StatefulWidget {
  final CustomerModel customer;

  const _EditCustomerBottomSheet({required this.customer});

  @override
  State<_EditCustomerBottomSheet> createState() =>
      _EditCustomerBottomSheetState();
}

class _EditCustomerBottomSheetState extends State<_EditCustomerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _creditLimitController;

  late int _selectedCategory;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer.name);
    _phoneController = TextEditingController(text: customer.phone);
    _addressController = TextEditingController(text: customer.address);
    _creditLimitController =
        TextEditingController(text: customer.creditLimit.toStringAsFixed(0));
    _selectedCategory = customerCategories.indexOf(customer.category);
    if (_selectedCategory == -1) _selectedCategory = 0;
    _latitude = customer.latitude;
    _longitude = customer.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (result.readableAddress != null &&
            result.readableAddress!.isNotEmpty) {
          _addressController.text = result.readableAddress!;
        }
      });
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onAddressEditedManually() {
    if (_latitude != null) {
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.customer.copyWith(
      name: _nameController.text.trim(),
      area: _addressController.text.trim(),
      category: customerCategories[_selectedCategory],
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text.trim()) ?? 0,
      latitude: _latitude,
      longitude: _longitude,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: 16.h),
                Text(
                  'تعديل بيانات العميل',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.text, fontSize: 16.sp),
                ),
                SizedBox(height: 18.h),
                const CustomerFieldLabel('اسم العميل'),
                CustomerTextField(
                  controller: _nameController,
                  hint: 'مثال: صيدلية النور',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اكتب اسم العميل'
                      : null,
                ),
                SizedBox(height: 14.h),
                const CustomerFieldLabel('رقم الهاتف'),
                CustomerTextField(
                  controller: _phoneController,
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.trim().length < 8)
                          ? 'رقم هاتف غير صحيح'
                          : null,
                ),
                SizedBox(height: 14.h),
                const CustomerFieldLabel('العنوان'),
                CustomerTextField(
                  controller: _addressController,
                  hint: 'مثال: المنصورة — طلخا',
                  onChanged: (_) => _onAddressEditedManually(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اكتب العنوان'
                      : null,
                ),
                SizedBox(height: 8.h),
                CustomerLocationButton(
                  isLoading: _isLocating,
                  hasLocation: _latitude != null,
                  onTap: _isLocating ? null : _useCurrentLocation,
                ),
                SizedBox(height: 14.h),
                const CustomerFieldLabel('التصنيف'),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (int i = 0; i < customerCategories.length; i++)
                      CustomerCategoryChip(
                        label: customerCategories[i],
                        isSelected: i == _selectedCategory,
                        onTap: () => setState(() => _selectedCategory = i),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),
                const CustomerFieldLabel('حد الائتمان'),
                CustomerTextField(
                  controller: _creditLimitController,
                  hint: '0',
                  keyboardType: TextInputType.number,
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
                      child: Text(
                        'حفظ التعديلات',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: Colors.white, fontSize: 14.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
