import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/payment_method_selector.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_section_card.dart';

class InvoicePaymentSection extends StatelessWidget {
  final QuickInvoiceState state;

  const InvoicePaymentSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuickInvoiceCubit>();
    final colors = context.colors;
    final rows = state.paymentSplitRows;

    return InvoiceSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'طريقة الدفع',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.text),
                ),
              ),
              TextButton(
                onPressed: cubit.toggleSplitPayment,
                child: Text(
                  state.splitPaymentMethods
                      ? 'إلغاء تقسيم المبلغ'
                      : 'تقسيم المبلغ على أكثر من طريقة',
                ),
              ),
            ],
          ),
          if (!state.splitPaymentMethods)
            PaymentMethodSelector(
              value: state.paymentMethod,
              onChanged: cubit.selectPaymentMethod,
            )
          else ...[
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: PaymentMethodSelector(
                      value: rows[i].method,
                      onChanged: (method) => cubit.selectSplitMethod(i, method),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rows[i].amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => cubit.changeSplitAmount(),
                      decoration: InputDecoration(
                        labelText: 'المبلغ ${i + 1}',
                      ),
                    ),
                  ),
                  if (rows.length > 2)
                    IconButton(
                      onPressed: () => cubit.removeSplitRow(i),
                      icon: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: colors.statusNotReached,
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: 6.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: cubit.addSplitRow,
                icon: const Icon(Icons.add),
                label: const Text('إضافة طريقة دفع'),
              ),
            ),
            Text(
              'مجموع طرق الدفع: ${state.paymentSplitTotal.toStringAsFixed(2)} من ${state.paidNow.toStringAsFixed(2)}',
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }
}
