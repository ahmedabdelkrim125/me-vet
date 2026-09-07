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

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _validationMessage;
  PaymentMethod? _paymentMethod;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _validationMessage = 'أدخل مبلغًا صحيحًا');
      return;
    }
    if (_paymentMethod == null) {
      setState(() => _validationMessage = 'اختر طريقة الدفع أولًا');
      return;
    }
    setState(() => _validationMessage = null);
    context.read<CustomerAccountCubit>().recordPayment(
          amount: amount,
          paymentMethod: _paymentMethod!,
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
                    style: AppTextStyles.cairoBold18
                        .copyWith(color: colors.text, fontSize: 15.sp)),
                SizedBox(height: 12.h),
                PaymentMethodSelector(
                  value: _paymentMethod,
                  onChanged: (method) => setState(() {
                    _paymentMethod = method;
                    _validationMessage = null;
                  }),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                SizedBox(height: 12.h),
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
            );
          },
        ),
      ),
    );
  }
}
