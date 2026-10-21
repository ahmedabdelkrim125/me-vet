import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_cubit.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_state.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_invoice_actions.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_line_row.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_totals_card.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/sale_type_button.dart';

class HistoricalInvoiceForm extends StatelessWidget {
  const HistoricalInvoiceForm({super.key});

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<HistoricalInvoiceCubit>();

    return BlocBuilder<HistoricalInvoiceCubit, HistoricalInvoiceState>(
      buildWhen: (previous, current) =>
          previous.loadingCatalog != current.loadingCatalog ||
          previous.invoiceDate != current.invoiceDate ||
          previous.isCashSale != current.isCashSale ||
          previous.lines != current.lines ||
          previous.paidNow > 0 != current.paidNow > 0 ||
          previous.paymentMethod != current.paymentMethod ||
          previous.discountAmount != current.discountAmount,
      builder: (context, state) {
        if (state.loadingCatalog) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 100.h),
          children: [
            InkWell(
              onTap: () => pickHistoricalInvoiceDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الفاتورة'),
                child: Text(_formatDate(state.invoiceDate)),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: SaleTypeButton(
                    label: 'آجل',
                    selected: !state.isCashSale,
                    onTap: () => cubit.setCashSale(false),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SaleTypeButton(
                    label: 'نقدي',
                    selected: state.isCashSale,
                    onTap: () => cubit.setCashSale(true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Text(
                  'الأصناف (${state.lines.length})',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.text, fontSize: 14.sp),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => addHistoricalProduct(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة منتج'),
                ),
              ],
            ),
            for (final line in state.lines)
              HistoricalLineRow(
                line: line,
                onTap: () => editHistoricalLine(context, line),
                onRemove: () => cubit.removeLine(line),
              ),
            SizedBox(height: 14.h),
            TextField(
              controller: cubit.discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              onChanged: cubit.changeDiscount,
              decoration: const InputDecoration(labelText: 'قيمة الخصم (ج.م)'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: cubit.paidNowController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              onChanged: cubit.changePaidNow,
              decoration:
                  const InputDecoration(labelText: 'المدفوع الآن (ج.م)'),
            ),
            if (state.paidNow > 0) ...[
              SizedBox(height: 12.h),
              DropdownButtonFormField<PaymentMethod>(
                value: state.paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                items: PaymentMethod.values
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.displayLabel),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) cubit.setPaymentMethod(value);
                },
              ),
            ],
            SizedBox(height: 12.h),
            TextField(
              controller: cubit.notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
            SizedBox(height: 18.h),
            HistoricalTotalsCard(
              subtotal: state.subtotal,
              discountAmount: state.discountAmount,
              total: state.total,
            ),
          ],
        );
      },
    );
  }
}
