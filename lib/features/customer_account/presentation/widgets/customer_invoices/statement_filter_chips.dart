import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_cubit.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_state.dart';

class StatementFilterChips extends StatelessWidget {
  const StatementFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<CustomerInvoicesCubit>();

    return BlocBuilder<CustomerInvoicesCubit, CustomerInvoicesState>(
      buildWhen: (previous, current) =>
          previous.showAll != current.showAll ||
          previous.loading != current.loading ||
          previous.invoices != current.invoices,
      builder: (context, state) => Wrap(
        spacing: 8.w,
        runSpacing: 4.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('آخر 6 شهور'),
            selected: !state.showAll,
            onSelected: (_) => cubit.setShowAll(false),
          ),
          ChoiceChip(
            label: const Text('كل الفواتير'),
            selected: state.showAll,
            onSelected: (_) => cubit.setShowAll(true),
          ),
          if (!state.loading)
            Text(
              '${state.visibleInvoices.length} فاتورة',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 11.sp),
            ),
        ],
      ),
    );
  }
}
