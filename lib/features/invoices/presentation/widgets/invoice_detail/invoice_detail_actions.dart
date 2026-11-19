import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/features/auth/domain/models/user_profile.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/invoices/data/invoice_deletion_service.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/invoice_share_service.dart';
import 'package:mivet_app/features/invoices/presentation/screens/edit_invoice_screen.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/apply_credit_dialog.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/edit_paid_amount_dialog.dart';
import 'package:printing/printing.dart';

import 'delete_invoice_dialog.dart';

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

Future<void> editInvoicePaidAmount(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  if (detail == null) return;
  final input = await showDialog<EditPaidInput>(
    context: context,
    builder: (_) => EditPaidAmountDialog(
      total: detail.totalAmount,
      paid: cubit.paidWithInvoice,
    ),
  );
  if (input == null || !context.mounted) return;
  await cubit.setPaidAmount(newPaid: input.amount, method: input.method);
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

Future<void> deleteInvoice(BuildContext context) async {
  final cubit = context.read<InvoiceDetailCubit>();
  final detail = cubit.state.detail;
  if (detail == null) return;
  final user = context.read<AuthCubit>().state.user;
  try {
    if (user?.role != UserRole.owner) {
      final repId =
          await InvoiceDeletionService.instance.getInvoiceRepId(detail.id);
      if (repId != user?.id) {
        if (context.mounted) {
          showAppInfo(context, 'تقدر تمسح الفواتير اللي أنت عملتها بس');
        }
        return;
      }
    }
  } catch (error) {
    if (context.mounted) showAppError(context, error);
    return;
  }
  if (!context.mounted) return;
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => DeleteInvoiceDialog(
      detail: detail,
      customerName: cubit.customerName,
      paidAmount: cubit.paidWithInvoice,
    ),
  );
  if (deleted == true && context.mounted) {
    showAppSuccess(context, 'تم حذف الفاتورة ${detail.code}');
    Navigator.of(context).pop(true);
  }
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
