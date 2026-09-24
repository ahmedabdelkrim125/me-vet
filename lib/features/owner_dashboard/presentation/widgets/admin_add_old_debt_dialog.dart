import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../../customer-visits/customers/domain/models/customer_model.dart';
import '../../data/admin_actions_service.dart';

/// تسجيل مديونية قديمة كانت على العميل قبل ما يتعمل له حساب على التطبيق.
/// بتدخل في نفس سجل حركة الحساب (ledger) اللي المندوب شايفه أصلًا، فمفيش
/// أي فرق بالنسبة له غير إن الرصيد بقى فيه المديونية القديمة دي.
class AdminAddOldDebtDialog extends StatefulWidget {
  final CustomerModel customer;

  const AdminAddOldDebtDialog({super.key, required this.customer});

  @override
  State<AdminAddOldDebtDialog> createState() => _AdminAddOldDebtDialogState();
}

class _AdminAddOldDebtDialogState extends State<AdminAddOldDebtDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _effectiveAt = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _effectiveAt = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'اكتب قيمة صحيحة للمديونية');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AdminActionsService().addOldDebt(
        customerId: widget.customer.id,
        amount: amount,
        effectiveAt: _effectiveAt,
        notes: _notesController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mapErrorToAppException(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'مديونية قديمة لـ${widget.customer.name}',
        style: AppTextStyles.cairoBold18
            .copyWith(color: AppColors.primary, fontSize: 15.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'قيمة المديونية (ج.م)',
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'تاريخ المديونية'),
              child: Text(
                '${_effectiveAt.year}/${_effectiveAt.month.toString().padLeft(2, '0')}/${_effectiveAt.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Text(
              _error!,
              style: TextStyle(color: AppColors.statusNotReached, fontSize: 13.sp),
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
          child: _loading
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('إضافة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
