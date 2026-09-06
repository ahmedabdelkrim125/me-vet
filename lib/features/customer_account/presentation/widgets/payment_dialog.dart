import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../customer-visits/customers/domain/models/collection_record_model.dart';
import '../../../customer-visits/customers/domain/models/invoice_record_model.dart';
import '../../../customer-visits/customers/data/invoices_repository.dart';
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
  final _notesController = TextEditingController();
  InvoiceRecordModel? _selectedInvoice;
  List<InvoiceRecordModel> _invoices = const [];
  bool _isLoadingInvoices = true;
  String? _invoiceError;
  String? _validationMessage;
  CollectionSource _source = CollectionSource.oldDebtPayment;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices = await InvoicesRepository.instance.getInvoicesForCustomer(
          context.read<CustomerAccountCubit>().state.customerId);
      if (!mounted) return;
      setState(() {
        _invoices = invoices.where((invoice) => invoice.remaining > 0).toList();
        _isLoadingInvoices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvoices = false;
        _invoiceError = 'تعذر تحميل فواتير العميل';
      });
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _validationMessage = 'أدخل مبلغًا صحيحًا');
      return;
    }
    if (_source == CollectionSource.newInvoicePayment &&
        _selectedInvoice == null) {
      setState(() => _validationMessage = 'اختر الفاتورة أولًا');
      return;
    }
    setState(() => _validationMessage = null);
    context.read<CustomerAccountCubit>().recordPayment(
          amount: amount,
          invoiceId: _source == CollectionSource.newInvoicePayment
              ? _selectedInvoice!.id
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
                    style: AppTextStyles.cairoBold18
                        .copyWith(color: colors.text, fontSize: 15.sp)),
                SizedBox(height: 12.h),
                _SourceSelector(
                  value: _source,
                  onChanged: (v) => setState(() {
                    _source = v;
                    _selectedInvoice = null;
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
                if (_source == CollectionSource.newInvoicePayment) ...[
                  SizedBox(height: 12.h),
                  _InvoiceSelector(
                    invoice: _selectedInvoice,
                    invoices: _invoices,
                    isLoading: _isLoadingInvoices,
                    errorMessage: _invoiceError,
                    onSelect: (invoice) =>
                        setState(() => _selectedInvoice = invoice),
                  ),
                ],
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

class _InvoiceSelector extends StatelessWidget {
  final InvoiceRecordModel? invoice;
  final List<InvoiceRecordModel> invoices;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<InvoiceRecordModel> onSelect;

  const _InvoiceSelector({
    required this.invoice,
    required this.invoices,
    required this.isLoading,
    required this.errorMessage,
    required this.onSelect,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (isLoading || invoices.isEmpty) return;
    final selected = await showModalBottomSheet<InvoiceRecordModel>(
      context: context,
      backgroundColor: context.colors.surface,
      showDragHandle: true,
      builder: (_) => _InvoicePickerSheet(invoices: invoices),
    );
    if (selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'الفاتورة'),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (errorMessage != null || invoices.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: 'الفاتورة'),
        child: Text(
          errorMessage ?? 'لا توجد فواتير مستحقة لهذا العميل',
          style: AppTextStyles.almaraiRegular14.copyWith(
            color: colors.textMuted,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8.r),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الفاتورة',
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          invoice == null
              ? 'اختر الفاتورة'
              : '${invoice!.code} — المتبقي ${invoice!.remaining.toStringAsFixed(0)} ج.م',
          style: AppTextStyles.almaraiRegular14.copyWith(color: colors.text),
        ),
      ),
    );
  }
}

class _InvoicePickerSheet extends StatelessWidget {
  final List<InvoiceRecordModel> invoices;

  const _InvoicePickerSheet({required this.invoices});

  String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        children: [
          Text(
            'اختر الفاتورة',
            style: AppTextStyles.cairoBold18
                .copyWith(color: colors.text, fontSize: 15.sp),
          ),
          SizedBox(height: 8.h),
          for (final invoice in invoices)
            Card(
              child: ListTile(
                title: Text(invoice.code),
                subtitle: Text(
                  'التاريخ: ${_date(invoice.date)}\n'
                  'الإجمالي: ${invoice.amount.toStringAsFixed(0)} ج.م — '
                  'المدفوع: ${invoice.paidAmount.toStringAsFixed(0)} ج.م\n'
                  'المتبقي: ${invoice.remaining.toStringAsFixed(0)} ج.م',
                ),
                onTap: () => Navigator.of(context).pop(invoice),
              ),
            ),
        ],
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
