import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_error_snackbar.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/customers_repository.dart';
import '../../../domain/models/customer_detail_model.dart';

Future<void> showCustomerCollectPaymentSheet(
  BuildContext context, {
  required CustomerDetailModel detail,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CollectPaymentSheet(detail: detail),
  );
}

class _CollectPaymentSheet extends StatefulWidget {
  final CustomerDetailModel detail;

  const _CollectPaymentSheet({required this.detail});

  @override
  State<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends State<_CollectPaymentSheet> {
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب مبلغًا صحيحًا')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // بنتأكد إن العملية نجحت فعليًا في Supabase الأول، وبعدين نقفل
      // الشيت ونعرض رسالة النجاح — مش العكس، عشان مانطلعش رسالة "تم"
      // للمستخدم وهي في الحقيقة فشلت.
      await CustomersRepository.instance.adjustBalance(
        widget.detail.customer.id,
        -amount,
        isCollection: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showAppError(context, e);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تسجيل تحصيل ${amount.toStringAsFixed(0)} ج.م من ${widget.detail.customer.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'تحصيل من ${widget.detail.customer.name}',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.text, fontSize: 16.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              'الرصيد الحالي: ${widget.detail.currentBalance.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
            SizedBox(height: 18.h),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: true,
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.text, fontSize: 20.sp),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'ج.م',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'تأكيد التحصيل',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: Colors.white, fontSize: 14.sp),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
