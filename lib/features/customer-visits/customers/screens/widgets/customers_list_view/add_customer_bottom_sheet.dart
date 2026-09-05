import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/location/location_service.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';
import 'customer_form_widgets.dart';

Future<CustomerModel?> showAddCustomerBottomSheet(BuildContext context) {
  return showModalBottomSheet<CustomerModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AddCustomerBottomSheet(),
  );
}

class _AddCustomerBottomSheet extends StatefulWidget {
  const _AddCustomerBottomSheet();

  @override
  State<_AddCustomerBottomSheet> createState() =>
      _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends State<_AddCustomerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();

  int _selectedCategory = 0;

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

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

    final customer = CustomerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      code: 'C-${1000 + DateTime.now().second}',
      area: _addressController.text.trim(),
      category: customerCategories[_selectedCategory],
      status: CustomerStatus.needsFollowUp,
      visitsThisMonth: 0,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text.trim()) ?? 0,
      latitude: _latitude,
      longitude: _longitude,
    );

    Navigator.of(context).pop(customer);
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
                  'إضافة عميل جديد',
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
                        'حفظ العميل',
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
