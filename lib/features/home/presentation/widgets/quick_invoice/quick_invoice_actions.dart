import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_exception.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/monitoring/error_reporter.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/quick_invoice_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/customer_picker_sheet.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/deferred_invoice_confirmation.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/product_picker_sheet.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/presentation/invoice_share_service.dart';
import 'package:printing/printing.dart';

Future<void> openInvoiceDatePicker(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final picked = await showDatePicker(
    context: context,
    initialDate: cubit.state.invoiceDate,
    firstDate: DateTime(2024),
    lastDate: DateTime(2030),
  );
  if (picked != null) cubit.setInvoiceDate(picked);
}

Future<void> openInvoiceCustomerPicker(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final customers = await cubit.loadCustomers();
  if (customers == null || !context.mounted) return;
  final picked = await showModalBottomSheet<InvoiceCustomerModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CustomerPickerSheet(customers: customers),
  );
  if (picked != null) await cubit.selectCustomer(picked);
}

Future<void> openInvoiceProductPicker(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final args = await cubit.prepareProductPicker();
  if (args == null || !context.mounted) return;
  final added = await showModalBottomSheet<List<InvoiceLineItemModel>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProductPickerSheet(args: args),
  );
  if (added != null) cubit.replaceLineItems(added);
}

Future<void> submitInvoice(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final readiness = cubit.checkIssueReadiness();
  if (readiness == IssueReadiness.rejected) return;
  if (readiness == IssueReadiness.needsConfirmation) {
    final confirmed =
        await showFullyDeferredInvoiceConfirmation(context, cubit.state);
    if (!confirmed || !context.mounted) return;
  }
  await cubit.issueInvoice();
}

Future<IssuedInvoiceInfo?> _issueBeforeDocument(
  BuildContext context,
  QuickInvoiceCubit cubit,
) async {
  if (cubit.state.isIssuing) return null;
  final readiness = cubit.checkIssueReadiness();
  if (readiness == IssueReadiness.rejected) return null;
  if (readiness == IssueReadiness.needsConfirmation) {
    final confirmed =
        await showFullyDeferredInvoiceConfirmation(context, cubit.state);
    if (!confirmed || !context.mounted) return null;
  }
  return cubit.issueInvoice(closeAfterIssue: false);
}

void _closeAfterDocument(
  BuildContext context,
  IssuedInvoiceInfo issued, {
  bool documentFailed = false,
}) {
  if (!context.mounted) return;
  Navigator.pop(context);
  if (documentFailed) {
    showAppError(
      context,
      AppException(
        'تم حفظ الفاتورة ${issued.invoiceNumber} لكن تعذر تجهيز الملف، افتحها من الفواتير وشاركها',
      ),
    );
    return;
  }
  showAppSuccess(
    context,
    'تم إصدار الفاتورة بنجاح: ${issued.invoiceNumber}',
  );
}

Future<void> printInvoice(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final repName = _currentRepName(context);
  final issued = await _issueBeforeDocument(context, cubit);
  if (issued == null) return;
  var documentFailed = false;
  try {
    final data = cubit.buildInvoiceData(
      repName,
      invoiceNumber: issued.invoiceNumber,
    );
    if (data != null) {
      final bytes = await InvoicePdfBuilder.build(data);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  } catch (e, st) {
    documentFailed = true;
    ErrorReporter.report(e, st);
  }
  if (!context.mounted) return;
  _closeAfterDocument(context, issued, documentFailed: documentFailed);
}

Future<void> shareInvoiceOnWhatsapp(BuildContext context) async {
  final cubit = context.read<QuickInvoiceCubit>();
  final repName = _currentRepName(context);
  final issued = await _issueBeforeDocument(context, cubit);
  if (issued == null || !context.mounted) return;
  var documentFailed = false;
  try {
    final data = cubit.buildInvoiceData(
      repName,
      invoiceNumber: issued.invoiceNumber,
    );
    if (data != null) {
      await InvoiceShareService.askAndShare(context, data);
    }
  } catch (e, st) {
    documentFailed = true;
    ErrorReporter.report(e, st);
  }
  if (!context.mounted) return;
  _closeAfterDocument(context, issued, documentFailed: documentFailed);
}

String _currentRepName(BuildContext context) {
  return context.read<AuthCubit>().state.user?.name ?? 'غير معروف';
}
