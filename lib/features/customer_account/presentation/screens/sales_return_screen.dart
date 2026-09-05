import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';

import '../../domain/entities/sales_return.dart';
import '../cubit/customer_account_cubit.dart';
import '../cubit/customer_account_state.dart';
import '../widgets/return_item_selector.dart';
import '../widgets/return_summary.dart';

/// Two-step return flow: pick the original invoice, then pick lines/quantities
/// to return from it. Requires a [CustomerAccountCubit] above it in the tree
/// (provided by [CustomerAccountScreen]'s `_ActionsBar`).
class SalesReturnScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const SalesReturnScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  List<InvoiceRecordModel>? _invoices;
  InvoiceFullDetail? _selectedInvoice;
  bool _loadingInvoices = true;
  bool _loadingDetail = false;
  final Map<String, int> _selectedQuantities = {};
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      final invoices =
          await InvoicesRepository.instance.getInvoicesForCustomer(widget.customerId);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loadingInvoices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInvoices = false);
      showAppError(context, e);
    }
  }

  Future<void> _selectInvoice(InvoiceRecordModel invoice) async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await InvoicesRepository.instance.getInvoiceDetailByCode(invoice.code);
      if (!mounted) return;
      setState(() {
        _selectedInvoice = detail;
        _loadingDetail = false;
        _selectedQuantities.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      showAppError(context, e);
    }
  }

  double get _returnTotal {
    final invoice = _selectedInvoice;
    if (invoice == null) return 0;
    var total = 0.0;
    for (final item in invoice.items) {
      final qty = _selectedQuantities[item.id] ?? 0;
      if (qty > 0) total += item.unitPrice * qty;
    }
    return total;
  }

  void _submit() {
    final invoice = _selectedInvoice;
    if (invoice == null) return;
    final items = _selectedQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => SalesReturnItemInput(invoiceItemId: e.key, quantity: e.value))
        .toList();
    if (items.isEmpty) return;
    context.read<CustomerAccountCubit>().submitSalesReturn(
          invoiceId: invoice.id,
          items: items,
          reason:
              _reasonController.text.trim().isEmpty ? 'مرتجع من العميل' : _reasonController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('مرتجع مبيعات'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
      ),
      body: BlocConsumer<CustomerAccountCubit, CustomerAccountState>(
        listenWhen: (p, c) => p.actionStatus != c.actionStatus,
        listener: (context, state) {
          final cubit = context.read<CustomerAccountCubit>();
          if (state.actionStatus == CustomerAccountActionStatus.success) {
            showAppSuccess(context, state.actionSuccessMessage ?? 'تم الحفظ');
            cubit.acknowledgeAction();
            Navigator.of(context).pop();
          } else if (state.actionStatus == CustomerAccountActionStatus.failure &&
              state.actionError != null) {
            showAppError(context, state.actionError!);
            cubit.acknowledgeAction();
          }
        },
        builder: (context, state) {
          final isSubmitting = state.actionStatus == CustomerAccountActionStatus.submitting;
          if (_selectedInvoice == null) {
            return _InvoicePicker(
              invoices: _invoices,
              isLoading: _loadingInvoices || _loadingDetail,
              onSelect: _selectInvoice,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'فاتورة ${_selectedInvoice!.code}',
                            style: AppTextStyles.cairoMedium16
                                .copyWith(color: colors.text, fontSize: 13.sp),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedInvoice = null),
                          child: const Text('تغيير الفاتورة'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    for (final item in _selectedInvoice!.items)
                      ReturnItemSelector(
                        item: item,
                        quantity: _selectedQuantities[item.id] ?? 0,
                        onChanged: (qty) => setState(() => _selectedQuantities[item.id] = qty),
                      ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'سبب الإرجاع'),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                    ),
                    SizedBox(height: 12.h),
                    ReturnSummary(total: _returnTotal),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: isSubmitting || _returnTotal <= 0 ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد المرتجع'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoicePicker extends StatelessWidget {
  final List<InvoiceRecordModel>? invoices;
  final bool isLoading;
  final ValueChanged<InvoiceRecordModel> onSelect;

  const _InvoicePicker({
    required this.invoices,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = invoices ?? const [];
    if (list.isEmpty) {
      return Center(
        child: Text('لا توجد فواتير لهذا العميل',
            style: AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final invoice = list[index];
        return Card(
          child: ListTile(
            title: Text(invoice.code),
            subtitle: Text(
              '${invoice.date.year}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.day.toString().padLeft(2, '0')} — ${invoice.amount.toStringAsFixed(0)} ج.م',
            ),
            trailing: Text(invoice.status.label),
            onTap: () => onSelect(invoice),
          ),
        );
      },
    );
  }
}