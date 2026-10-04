import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mivet_app/features/rep_session/data/rep_session_store.dart';
import 'package:printing/printing.dart';

import '../../../customer_account/data/repositories/payment_breakdown_repository.dart';
import '../../../customer_account/domain/entities/payment_breakdown.dart';
import '../../../customer_account/domain/entities/payment_method.dart';
import '../../../customer_account/presentation/widgets/payment_method_selector.dart';
import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../data/invoices_repository.dart';
import 'edit_invoice_screen.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceCode;
  final String customerName;
  final double previousBalanceAtView;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceCode,
    required this.customerName,
    this.previousBalanceAtView = 0,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceFullDetail? _detail;
  List<PaymentBreakdownLine> _oldDebtLines = const [];
  bool _loading = true;
  bool _hasError = false;
  double _applicableCredit = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await InvoicesRepository.instance
          .getInvoiceDetailByCode(widget.invoiceCode);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _hasError = false;
      });
      unawaited(_loadOldDebt(detail.id));
      unawaited(_loadApplicableCredit(detail));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadApplicableCredit(InvoiceFullDetail detail) async {
    if (detail.remaining <= 0) {
      if (mounted) setState(() => _applicableCredit = 0);
      return;
    }
    try {
      final credit = await InvoicesRepository.instance
          .getInvoiceApplicableCredit(detail.id);
      if (!mounted) return;
      setState(() => _applicableCredit = credit);
    } catch (_) {
      if (mounted) setState(() => _applicableCredit = 0);
    }
  }

  Future<void> _loadOldDebt(String invoiceId) async {
    try {
      final lines =
          await PaymentBreakdownRepository.instance.getForInvoice(invoiceId);
      if (!mounted) return;
      setState(() {
        _oldDebtLines = lines.where((l) => !l.isOwnInvoice).toList();
      });
    } catch (_) {}
  }

  Future<void> _editInvoice() async {
    final detail = _detail;
    if (detail == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditInvoiceScreen(
          invoice: detail,
          customerName: widget.customerName,
          customerId: detail.customerId,
        ),
      ),
    );

    if (changed == true && mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<String> _resolveRepName() async {
    final activeRep = await RepSessionStore.instance.getActiveRep();
    final activeRepName = activeRep?.name.trim();
    if (activeRepName != null && activeRepName.isNotEmpty) {
      return activeRepName;
    }

    final signedInUserName = context.read<AuthCubit>().state.user?.name.trim();
    if (signedInUserName != null && signedInUserName.isNotEmpty) {
      return signedInUserName;
    }

    return '';
  }

  double _discountOf(InvoiceFullDetail detail) {
    final fromSubtotal = detail.subtotal - detail.totalAmount;
    return detail.discountAmount > fromSubtotal
        ? detail.discountAmount
        : (fromSubtotal > 0 ? fromSubtotal : 0.0);
  }

  Future<Uint8List> _buildPdf(InvoiceFullDetail detail) async {
    final actualCreatorName = detail.creatorName?.trim();
    final repName = (actualCreatorName != null && actualCreatorName.isNotEmpty)
        ? '$actualCreatorName${detail.isFromAdmin ? ' (إدارة)' : ''}'
        : await _resolveRepName();
    return InvoicePdfBuilder.build(
      InvoicePdfData(
        invoiceNumber: detail.code,
        date: detail.date,
        customerName: widget.customerName,
        repName: repName,
        items: detail.items
            .map(
              (i) => InvoicePdfLineItem(
                name: i.productName,
                quantity: i.quantity,
                price: i.unitPrice,
                total: i.lineTotal,
              ),
            )
            .toList(),
        invoiceTotal: detail.totalAmount,
        discountAmount: _discountOf(detail),
        previousBalance: widget.previousBalanceAtView,
        totalDue: detail.totalAmount + widget.previousBalanceAtView,
        paidNow: detail.paidNow,
        remaining: detail.remaining < 0 ? 0 : detail.remaining,
        oldDebtCollected: _oldDebtLines
            .map(
              (l) => InvoicePdfOldDebtLine(
                invoiceCode: l.invoiceCode ?? 'رصيد سابق',
                amount: l.amount,
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _collectPayment() async {
    final detail = _detail;
    if (detail == null) return;

    final remaining = detail.remaining < 0 ? 0.0 : detail.remaining;
    final amountController = TextEditingController(
      text: remaining.toStringAsFixed(0),
    );
    PaymentMethod method = PaymentMethod.cash;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('تعديل المبلغ المدفوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('المتبقي حاليًا: ${remaining.toStringAsFixed(0)} ج.م'),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'المبلغ المحصّل دلوقتي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PaymentMethodSelector(
                value: method,
                onChanged: (value) => setDialogState(() => method = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد التحصيل'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      showAppError(context, 'المبلغ غير صحيح');
      return;
    }

    try {
      await InvoicesRepository.instance.collectAgainstInvoice(
        invoiceId: detail.id,
        amount: amount,
        method: method,
      );
      if (!mounted) return;
      setState(() => _loading = true);
      await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _applyCredit() async {
    final detail = _detail;
    if (detail == null || _applicableCredit <= 0) return;

    final maxAmount = _applicableCredit;
    final controller =
        TextEditingController(text: maxAmount.toStringAsFixed(0));

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final parsed = double.tryParse(controller.text.trim());
          final valid = parsed != null && parsed > 0 && parsed <= maxAmount;

          return AlertDialog(
            title: const Text('سداد من رصيد العميل'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'المتبقي على الفاتورة: ${detail.remaining.toStringAsFixed(0)} ج.م'),
                const SizedBox(height: 4),
                Text('رصيد العميل المتاح: ${maxAmount.toStringAsFixed(0)} ج.م'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المسدد من الرصيد',
                    suffixText: 'ج.م',
                    border: const OutlineInputBorder(),
                    errorText: parsed != null && parsed > maxAmount
                        ? 'أكبر من الرصيد المتاح'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'المبلغ هيتحسب مدفوع على الفاتورة من فلوس العميل الموجودة عندنا، ومش هيدخل خزنة جديدة.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed:
                    valid ? () => Navigator.pop(dialogContext, parsed) : null,
                child: const Text('تأكيد السداد'),
              ),
            ],
          );
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (amount == null || !mounted) return;

    try {
      await InvoicesRepository.instance.applyCustomerCreditToInvoice(
        invoiceId: detail.id,
        amount: amount,
      );
      if (!mounted) return;
      showAppSuccess(context, 'تم سداد الفاتورة من رصيد العميل');
      setState(() => _loading = true);
      await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _adjustOverpayment() async {
    final detail = _detail;
    if (detail == null) return;

    final total = detail.totalAmount;
    final paid = detail.paidNow;
    final controller = TextEditingController(text: total.toStringAsFixed(0));

    final newPaid = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final parsed = double.tryParse(controller.text.trim());
          final valid =
              parsed != null && parsed >= 0 && parsed <= total && parsed < paid;
          final overLimit = parsed != null && parsed > total;
          final excess = valid ? paid - parsed : 0.0;

          return AlertDialog(
            title: const Text('تعديل المبلغ المدفوع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إجمالي الفاتورة: ${total.toStringAsFixed(0)} ج.م'),
                const SizedBox(height: 4),
                Text('المدفوع حاليًا: ${paid.toStringAsFixed(0)} ج.م'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع الجديد',
                    suffixText: 'ج.م',
                    border: const OutlineInputBorder(),
                    errorText: overLimit
                        ? 'أكبر من إجمالي الفاتورة'
                        : (parsed != null && parsed >= paid
                            ? 'لازم يكون أقل من المدفوع حاليًا'
                            : null),
                  ),
                ),
                const SizedBox(height: 12),
                if (valid)
                  Text(
                    '${excess.toStringAsFixed(0)} ج.م هيفضلوا رصيد دائن للعميل، يقدر ياخد بيهم منتجات في فواتير جاية أو يتردوله.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMuted,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed:
                    valid ? () => Navigator.pop(dialogContext, parsed) : null,
                child: const Text('تأكيد التعديل'),
              ),
            ],
          );
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (newPaid == null || !mounted) return;

    try {
      await InvoicesRepository.instance.releaseInvoiceOverpayment(
        invoiceId: detail.id,
        newPaid: newPaid,
      );
      if (!mounted) return;
      showAppSuccess(context, 'تم تعديل المبلغ المدفوع');
      setState(() => _loading = true);
      await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _printPdf() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      final bytes = await _buildPdf(detail);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _sharePdf() async {
    final detail = _detail;
    if (detail == null) return;

    try {
      final bytes = await _buildPdf(detail);
      await PdfExport.share(bytes, '${detail.code}.pdf');
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              code: widget.invoiceCode,
              onBack: () => Navigator.of(context).pop(),
              onEdit: _detail == null ? null : _editInvoice,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError || _detail == null
                      ? Center(
                          child: Text(
                            'تعذر تحميل تفاصيل الفاتورة',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      : _DetailBody(
                          detail: _detail!,
                          oldDebtLines: _oldDebtLines,
                          onCollectPayment: _collectPayment,
                          onAdjustOverpayment: _adjustOverpayment,
                          applicableCredit: _applicableCredit,
                          onApplyCredit: _applyCredit,
                        ),
            ),
            if (!_loading && _detail != null)
              _FooterActions(
                onPrint: _printPdf,
                onShare: _sharePdf,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String code;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const _Header({
    required this.code,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              CupertinoIcons.back,
              color: colors.primary,
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'تفاصيل الفاتورة $code',
              style: AppTextStyles.cairoBold18.copyWith(
                color: colors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'تعديل الفاتورة',
            icon: Icon(
              Icons.edit_outlined,
              color: colors.primary,
              size: 21.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final InvoiceFullDetail detail;
  final List<PaymentBreakdownLine> oldDebtLines;
  final VoidCallback onCollectPayment;
  final VoidCallback onAdjustOverpayment;
  final double applicableCredit;
  final VoidCallback onApplyCredit;

  const _DetailBody({
    required this.detail,
    required this.onCollectPayment,
    required this.onAdjustOverpayment,
    required this.applicableCredit,
    required this.onApplyCredit,
    this.oldDebtLines = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        if (detail.isFromAdmin) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    color: colors.primary, size: 15.sp),
                SizedBox(width: 6.w),
                Text(
                  detail.creatorName == null || detail.creatorName!.isEmpty
                      ? 'فاتورة من الإدارة'
                      : 'فاتورة من الإدارة — ${detail.creatorName}',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.primary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
        _InfoCard(
          children: [
            _InfoRow(
              label: 'التاريخ',
              value:
                  '${detail.date.year}/${detail.date.month.toString().padLeft(2, '0')}/${detail.date.day.toString().padLeft(2, '0')}',
            ),
            _InfoRow(
              label: 'الحالة',
              value: detail.statusLabel,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'المنتجات',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: colors.text,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        for (final item in detail.items) _ItemRow(item: item),
        SizedBox(height: 16.h),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'الإجمالي قبل الخصم',
              value: '${detail.subtotal.toStringAsFixed(0)} ج.م',
            ),
            if (detail.discountPercent > 0)
              _InfoRow(
                label: 'الخصم',
                value: '${detail.discountPercent.toStringAsFixed(0)}%',
              ),
            _InfoRow(
              label: 'الإجمالي',
              value: '${detail.totalAmount.toStringAsFixed(0)} ج.م',
              highlight: true,
            ),
            _InfoRow(
              label: 'المدفوع الآن',
              value: '${detail.paidNow.toStringAsFixed(0)} ج.م',
            ),
            _InfoRow(
              label: 'المتبقي على العميل',
              value:
                  '${(detail.remaining < 0 ? 0 : detail.remaining).toStringAsFixed(0)} ج.م',
            ),
          ],
        ),
        if (detail.remaining > 0) ...[
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCollectPayment,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('تعديل المبلغ المدفوع'),
            ),
          ),
          if (applicableCredit > 0) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onApplyCredit,
                icon:
                    const Icon(Icons.account_balance_wallet_outlined, size: 16),
                label: Text(
                    'سداد من رصيد العميل (${applicableCredit.toStringAsFixed(0)} ج.م)'),
              ),
            ),
          ],
        ] else if (detail.paidNow > detail.totalAmount) ...[
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdjustOverpayment,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('تعديل المبلغ المدفوع'),
            ),
          ),
        ],
        if (oldDebtLines.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            'دين قديم اتحصّل مع الفاتورة دي',
            style: AppTextStyles.cairoMedium16.copyWith(
              color: colors.text,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          _InfoCard(
            children: [
              for (final line in oldDebtLines)
                _InfoRow(
                  label: line.invoiceCode ?? 'رصيد سابق',
                  value: '${line.amount.toStringAsFixed(0)} ج.م',
                ),
              _InfoRow(
                label: 'إجمالي التحصيل مع الفاتورة',
                value:
                    '${(detail.paidNow + oldDebtLines.fold(0.0, (sum, l) => sum + l.amount)).toStringAsFixed(0)} ج.م',
                highlight: true,
              ),
            ],
          ),
        ],
        if (detail.notes != null && detail.notes!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'ملاحظات',
                value: detail.notes!,
              ),
            ],
          ),
        ],
        if (detail.lastEditReason != null &&
            detail.lastEditReason!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'ملاحظة آخر تعديل',
                value: detail.lastEditReason!,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InvoiceItemRow item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: colors.text,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.lineTotal.toStringAsFixed(0)} ج.م',
            style: AppTextStyles.cairoBold18.copyWith(
              color: colors.primary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: colors.textMuted,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
              child: Text(value,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: highlight ? colors.primary : colors.text,
                    fontSize: highlight ? 14.sp : 12.sp,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _FooterActions({
    required this.onPrint,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrint,
              icon: Icon(Icons.print_outlined, size: 18.sp),
              label: const Text('طباعة'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'مشاركة PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
