import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../data/owner_service.dart';

class AddRepDialog extends StatefulWidget {
  final UserProfile? rep;

  const AddRepDialog({super.key, this.rep});

  @override
  State<AddRepDialog> createState() => _AddRepDialogState();
}

class _AddRepDialogState extends State<AddRepDialog> {
  final _ownerService = OwnerService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isEditMode => widget.rep != null;

  @override
  void initState() {
    super.initState();
    if (widget.rep != null) {
      _nameController.text = widget.rep!.name;
      _phoneController.text = widget.rep!.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isEditMode) {
        final pin = _pinController.text.trim();
        await _ownerService.updateRep(
          repId: widget.rep!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          pin: pin.isEmpty ? null : pin,
        );
      } else {
        await _ownerService.createRep(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          pin: _pinController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'تعديل بيانات المندوب' : 'إضافة مندوب جديد',
        style: AppTextStyles.cairoBold18
            .copyWith(color: AppColors.primary, fontSize: 17.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'اسم المندوب'),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              labelText: 'رقم الموبايل',
              hintText: '01xxxxxxxxx',
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText:
                  _isEditMode ? 'PIN جديد (اختياري)' : 'رمز PIN (6 أرقام)',
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.statusNotReached,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: _loading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditMode ? 'حفظ التعديلات' : 'إضافة',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}