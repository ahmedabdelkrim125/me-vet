import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/location/location_service.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/models/customer_model.dart';
import '../../../domain/models/customer_status.dart';

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

  static const List<String> _categories = [
    'صيدلية بيطرية',
    'عيادة بيطرية',
    'دكتور بيطري',
    'مزرعة دواجن',
    'مزرعة لارج',
  ];

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
        // العنوان المكتشف بيتحط في الحقل، وبيفضل قابل للتعديل اليدوي
        // عادي بعد كده لو عايز تظبطه.
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

  /// أي تعديل يدوي في العنوان بعد ما نحدد GPS معناه المستخدم مش واثق في
  /// النتيجة أو غيّرها بنفسه، فمنسيبش وهم إن الإحداثيات القديمة لسه صح.
  void _onAddressEditedManually() {
    if (_latitude != null)
      setState(() {
        _latitude = null;
        _longitude = null;
      });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      code: 'C-${1000 + DateTime.now().second}',
      area: _addressController.text.trim(),
      category: _categories[_selectedCategory],
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
                const _FieldLabel('اسم العميل'),
                _CustomerTextField(
                  controller: _nameController,
                  hint: 'مثال: صيدلية النور',
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اكتب اسم العميل'
                      : null,
                ),
                SizedBox(height: 14.h),
                const _FieldLabel('رقم الهاتف'),
                _CustomerTextField(
                  controller: _phoneController,
                  hint: '01xxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.trim().length < 8)
                          ? 'رقم هاتف غير صحيح'
                          : null,
                ),
                SizedBox(height: 14.h),
                const _FieldLabel('العنوان'),
                _CustomerTextField(
                  controller: _addressController,
                  hint: 'مثال: المنصورة — طلخا',
                  onChanged: (_) => _onAddressEditedManually(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اكتب العنوان'
                      : null,
                ),
                SizedBox(height: 8.h),
                _LocationButton(
                  isLoading: _isLocating,
                  hasLocation: _latitude != null,
                  onTap: _isLocating ? null : _useCurrentLocation,
                ),
                SizedBox(height: 14.h),
                const _FieldLabel('التصنيف'),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (int i = 0; i < _categories.length; i++)
                      _CategoryChip(
                        label: _categories[i],
                        isSelected: i == _selectedCategory,
                        onTap: () => setState(() => _selectedCategory = i),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),
                const _FieldLabel('حد الائتمان'),
                _CustomerTextField(
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.cairoMedium16
          .copyWith(color: context.colors.primary, fontSize: 12.sp),
    );
  }
}

class _CustomerTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _CustomerTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        style:
            AppTextStyles.cairoRegular14.copyWith(color: context.colors.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.colors.surface,
          hintText: hint,
          hintStyle: AppTextStyles.almaraiRegular14
              .copyWith(color: context.colors.textMuted, fontSize: 12.sp),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: context.colors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final bool isLoading;
  final bool hasLocation;
  final VoidCallback? onTap;

  const _LocationButton({
    required this.isLoading,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = hasLocation ? colors.primary : colors.statusNotReached;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 15.w,
                height: 15.w,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            else
              Icon(
                hasLocation
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.location_fill,
                size: 16.sp,
                color: accent,
              ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                isLoading
                    ? 'بيتم تحديد موقعك...'
                    : hasLocation
                        ? 'تم تحديد الموقع بدقة — اضغط لإعادة التحديد'
                        : 'أنا هنا دلوقتي — حدد موقعي بدقة',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: accent, fontSize: 11.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(CupertinoIcons.check_mark,
                  size: 13.sp, color: context.colors.primary),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.textMuted,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
