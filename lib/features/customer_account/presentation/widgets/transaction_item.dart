import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/customer_transaction.dart';
import 'transaction_type_badge.dart';

class TransactionItem extends StatelessWidget {
  final CustomerTransaction transaction;

  const TransactionItem({super.key, required this.transaction});

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _dateLabel {
    final d = transaction.occurredAt;
    return '${d.year}/${_two(d.month)}/${_two(d.day)}';
  }

  String get _timeLabel {
    final d = transaction.occurredAt;
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasDebit = transaction.debit > 0;
    final hasCredit = transaction.credit > 0;
    final hasFooter =
        transaction.repId != null || (transaction.notes?.isNotEmpty ?? false);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TransactionTypeBadge(type: transaction.type),
              SizedBox(width: 8.w),
              if (transaction.referenceCode != null)
                Expanded(
                  child: Text(
                    transaction.referenceCode!,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp),
                  ),
                )
              else
                const Spacer(),
              Text(
                '$_dateLabel  $_timeLabel',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 10.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              if (hasDebit)
                Expanded(
                  child: _AmountLabel(
                    label: 'مدين',
                    amount: transaction.debit,
                    color: colors.statusNotReached,
                  ),
                ),
              if (hasCredit)
                Expanded(
                  child: _AmountLabel(
                    label: 'دائن',
                    amount: transaction.credit,
                    color: colors.primary,
                  ),
                ),
              Expanded(
                child: _AmountLabel(
                  label: 'الرصيد بعدها',
                  amount: transaction.balanceAfter,
                  color: colors.text,
                ),
              ),
            ],
          ),
          if (hasFooter) ...[
            SizedBox(height: 6.h),
            if (transaction.repId != null)
              Text(
                'المندوب: ${transaction.repId}',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 10.sp),
              ),
            if (transaction.notes?.isNotEmpty ?? false)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  transaction.notes!,
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountLabel({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 9.sp)),
        Text('${amount.toStringAsFixed(0)} ج.م',
            style: AppTextStyles.cairoMedium16.copyWith(color: color, fontSize: 12.sp)),
      ],
    );
  }
}