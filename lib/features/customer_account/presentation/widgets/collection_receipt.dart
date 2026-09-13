import 'package:flutter/material.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/collection_receipt.dart' as domain;
import '../../domain/entities/payment_method.dart';

class CollectionReceipt extends StatelessWidget {
  final domain.CollectionReceipt data;

  const CollectionReceipt({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                AppImages.logoSplash,
                height: 60.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'إيصال تحصيل',
              textAlign: TextAlign.center,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: colors.text,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            _ReceiptRow(label: 'العميل', value: data.customerName),
            _ReceiptRow(label: 'المندوب', value: data.representativeName),
            _ReceiptRow(
              label: 'المبلغ المحصل',
              value: '${_formatAmount(data.amount)} ج.م',
            ),
            _ReceiptRow(
              label: 'طريقة الدفع',
              value: data.paymentMethod.displayLabel,
            ),
            _ReceiptRow(
              label: 'الرصيد بعد التحصيل',
              value: '${_formatAmount(data.balanceAfterCollection)} ج.م',
            ),
            _ReceiptRow(
              label: 'التاريخ',
              value: _formatDate(data.collectedAt),
            ),
            _ReceiptRow(
              label: 'الوقت',
              value: _formatTime(data.collectedAt),
            ),
            if (data.collectionCode != null)
              _ReceiptRow(label: 'كود التحصيل', value: data.collectionCode!),
            if (data.notes != null && data.notes!.isNotEmpty)
              _ReceiptRow(label: 'ملاحظات', value: data.notes!),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: colors.textMuted,
              fontSize: 11.sp,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: AppTextStyles.almaraiRegular14.copyWith(
                color: colors.text,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
