import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/invoice_share_service.dart';
import 'package:mivet_app/features/invoices/presentation/screens/edit_invoice_screen.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/adjust_overpayment_dialog.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/apply_credit_dialog.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/collect_invoice_payment_dialog.dart';
import 'package:printing/printing.dart';

Future<void> openEditInvoice(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  if (detail == null) return;
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditInvoiceScreen(
        invoice: detail,
        customerName: cubit.customerName,
        customerId: detail.customerId,
      ),
    ),
  );
  if (changed == true && context.mounted) await cubit.reload();
}

Future<void> collectInvoicePayment(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  if (detail == null) return;
  final remaining = detail.remaining < 0 ? 0.0 : detail.remaining;
  final input = await showDialog<CollectPaymentInput>(
    context: context,
    builder: (_) => CollectInvoicePaymentDialog(remaining: remaining),
  );
  if (input == null || !context.mounted) return;
  final amount = input.amount;
  if (amount == null || amount <= 0) {
    showAppError(context, 'المبلغ غير صحيح');
    return;
  }
  await cubit.collectPayment(amount: amount, method: input.method);
}

Future<void> applyInvoiceCredit(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  final credit = cubit.state.applicableCredit;
  if (detail == null || credit <= 0) return;
  final amount = await showDialog<double>(
    context: context,
    builder: (_) => ApplyCreditDialog(
      maxAmount: credit,
      remaining: detail.remaining,
    ),
  );
  if (amount == null || !context.mounted) return;
  await cubit.applyCredit(amount);
}

Future<void> adjustInvoiceOverpayment(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  if (detail == null) return;
  final newPaid = await showDialog<double>(
    context: context,
    builder: (_) => AdjustOverpaymentDialog(
      total: detail.totalAmount,
      paid: detail.paidNow,
    ),
  );
  if (newPaid == null || !context.mounted) return;
  await cubit.releaseOverpayment(newPaid);
}

Future<void> printInvoicePdf(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final fallbackRepName = context.read<AuthCubit>().state.user?.name;
  try {
    final data = await cubit.buildInvoiceData(fallbackRepName: fallbackRepName);
    if (data == null) return;
    final bytes = await InvoicePdfBuilder.build(data);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  } catch (error) {
    if (context.mounted) showAppError(context, error);
  }
}

Future<void> shareInvoicePdf(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final fallbackRepName = context.read<AuthCubit>().state.user?.name;
  try {
    final data = await cubit.buildInvoiceData(fallbackRepName: fallbackRepName);
    if (data == null || !context.mounted) return;
    await InvoiceShareService.askAndShare(context, data);
  } catch (error) {
    if (context.mounted) showAppError(context, error);
  }
}
