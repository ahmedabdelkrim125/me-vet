import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../data/owner_service.dart';

class AddRepDialog extends StatefulWidget {
  const AddRepDialog({super.key});

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
      await _ownerService.createRep(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
      );
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
        'إضافة مندوب جديد',
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
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: 'رمز PIN (4 أرقام)',
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
              : const Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
