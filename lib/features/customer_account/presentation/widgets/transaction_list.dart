import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../domain/entities/customer_transaction.dart';
import 'transaction_item.dart';

class TransactionList extends StatelessWidget {
  final List<CustomerTransaction> transactions;
  final bool isLoading;

  const TransactionList({
    super.key,
    required this.transactions,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isLoading && transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: Center(
          child: Text(
            'لسه مفيش معاملات مسجلة على الحساب ده',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final tx in transactions) TransactionItem(transaction: tx),
      ],
    );
  }
}