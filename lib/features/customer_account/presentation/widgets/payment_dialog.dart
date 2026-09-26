import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';
import '../../domain/entities/payment_method.dart';
import 'payment_method_selector.dart';

Future<void> showPaymentDialog(BuildContext context) {
  final cubit = context.read<CustomerAccountCubit>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const PaymentDialog(),
    ),
  );
}

class _PaymentSplitRow {
  PaymentMethod? method;
  final TextEditingController amountController = TextEditingController();

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;

  void dispose() => amountController.dispose();
}

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _notesController = TextEditingController();
  final List<_PaymentSplitRow> _rows = [_PaymentSplitRow()];
  String? _validationMessage;

  bool get _isSplit => _rows.length > 1;

  double get _total => _rows.fold(0, (sum, row) => sum + row.amount);

  @override
  void dispose() {
    _notesController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_PaymentSplitRow());
      _validationMessage = null;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      _validationMessage = null;
    });
  }

  void _submit() {
    for (final row in _rows) {
      if (row.method == null) {
        setState(() => _validationMessage = 'اختر طريقة الدفع لكل سطر');
        return;
      }
      if (row.amount <= 0) {
        setState(() => _validationMessage = 'أدخل مبلغًا صحيحًا لكل سطر');
        return;
      }
    }

    setState(() => _validationMessage = null);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_rows.length == 1) {
      context.read<CustomerAccountCubit>().recordPayment(
            amount: _rows.first.amount,
            paymentMethod: _rows.first.method!,
            notes: notes,
          );
    } else {
      context.read<CustomerAccountCubit>().recordPaymentSplit(
            payments: _rows
                .map((row) => PaymentSplitEntry(
                      method: row.method!,
                      amount: row.amount,
                    ))
                .toList(),
            notes: notes,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(16.w),
        child: BlocConsumer<CustomerAccountCubit, CustomerAccountState>(
          listenWhen: (p, c) => p.actionStatus != c.actionStatus,
          listener: (context, state) {
            if (state.actionStatus == CustomerAccountActionStatus.success) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final isSubmitting =
                state.actionStatus == CustomerAccountActionStatus.submitting;
            return SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تسجيل تحصيل',
                    style: AppTextStyles.cairoBold18
                        .copyWith(color: colors.text, fontSize: 15.sp)),
                SizedBox(height: 12.h),
                for (var i = 0; i < _rows.length; i++) ...[
                  if (i > 0) ...[
                    SizedBox(height: 12.h),
                    Divider(color: colors.text.withValues(alpha: 0.1)),
                    SizedBox(height: 4.h),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isSplit ? 'طريقة الدفع ${i + 1}' : 'طريقة الدفع',
                          style: AppTextStyles.almaraiRegular14
                              .copyWith(color: colors.text),
                        ),
                      ),
                      if (_isSplit)
                        IconButton(
                          onPressed: () => _removeRow(i),
                          icon: Icon(Icons.close,
                              size: 18.sp, color: colors.statusNotReached),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  PaymentMethodSelector(
                    value: _rows[i].method,
                    onChanged: (method) => setState(() {
                      _rows[i].method = method;
                      _validationMessage = null;
                    }),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _rows[i].amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _isSplit ? 'المبلغ ${i + 1}' : 'المبلغ',
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة طريقة دفع تانية'),
                  ),
                ),
                if (_isSplit) ...[
                  Text(
                    'إجمالي التحصيل: ${_total.toStringAsFixed(2)}',
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.text),
                  ),
                  SizedBox(height: 8.h),
                ],
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
                if (_validationMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _validationMessage!,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.statusNotReached),
                  ),
                ],
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد التحصيل'),
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}
