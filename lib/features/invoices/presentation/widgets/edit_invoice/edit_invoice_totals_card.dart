import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/edit_invoice_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_money_row.dart';

class EditInvoiceTotalsCard extends StatelessWidget {
  const EditInvoiceTotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<EditInvoiceCubit>();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: BlocBuilder<EditInvoiceCubit, EditInvoiceState>(
        buildWhen: (previous, current) =>
            previous.subtotal != current.subtotal ||
            previous.total != current.total,
        builder: (context, state) => Column(
          children: [
            EditInvoiceMoneyRow(
              label: 'الإجمالي قبل الخصم',
              value: state.subtotal,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'قيمة الخصم',
                    style: AppTextStyles.almaraiRegular14.copyWith(
                      color: colors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120.w,
                  child: TextField(
                    controller: cubit.discountController,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      suffixText: 'ج.م',
                      isDense: true,
                    ),
                    onChanged: cubit.changeDiscount,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Divider(color: colors.border),
            EditInvoiceMoneyRow(
              label: 'الإجمالي بعد الخصم',
              value: state.total,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}
