import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';

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

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountController = TextEditingController();
  final _invoiceIdController = TextEditingController();
  final _notesController = TextEditingController();
  CollectionSource _source = CollectionSource.oldDebtPayment;

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    context.read<CustomerAccountCubit>().recordPayment(
          amount: amount,
          invoiceId: _source == CollectionSource.newInvoicePayment &&
                  _invoiceIdController.text.trim().isNotEmpty
              ? _invoiceIdController.text.trim()
              : null,
          source: _source,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تسجيل تحصيل',
                    style:
                        AppTextStyles.cairoBold18.copyWith(color: colors.text, fontSize: 15.sp)),
                SizedBox(height: 12.h),
                _SourceSelector(
                  value: _source,
                  onChanged: (v) => setState(() => _source = v),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                if (_source == CollectionSource.newInvoicePayment) ...[
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _invoiceIdController,
                    decoration:
                        const InputDecoration(labelText: 'معرف الفاتورة (اختياري)'),
                  ),
                ],
                SizedBox(height: 12.h),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
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
            );
          },
        ),
      ),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  final CollectionSource value;
  final ValueChanged<CollectionSource> onChanged;

  const _SourceSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CollectionSource>(
      segments: CollectionSource.values
          .map((s) => ButtonSegment(value: s, label: Text(s.label)))
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}