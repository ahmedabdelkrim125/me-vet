import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/months_before.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/invoice_detail_screen.dart';
import 'package:mivet_app/features/customer_account/data/repositories/payment_breakdown_repository.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_breakdown.dart';

const _arabicMonths = [
  '',
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Every invoice of one customer, grouped by month. Shows the last 6 months
/// by default, with a switch to see all of them.
///
/// This used to be a section inside the customer details screen; it now lives
/// on its own page, reached from the customer account screen.
class CustomerInvoicesScreen extends StatefulWidget {
  static const int recentMonths = 6;

  final String customerId;
  final String customerName;

  /// Passed to the invoice details screen ("balance at the time of viewing").
  final double currentBalance;

  /// When set, an "export PDF" action is shown in the app bar.
  final VoidCallback? onExportPdf;

  const CustomerInvoicesScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.currentBalance = 0,
    this.onExportPdf,
  });

  @override
  State<CustomerInvoicesScreen> createState() => _CustomerInvoicesScreenState();
}

class _CustomerInvoicesScreenState extends State<CustomerInvoicesScreen> {
  List<InvoiceRecordModel> _invoices = const [];
  List<PaymentBreakdown> _payments = const [];

  /// Invoice id -> the other invoice it was collected together with, for
  /// invoices settled as old debt rather than paid on their own. See
  /// [PaymentBreakdownRepository.getCollectionSourcesForCustomer].
  Map<String, String?> _collectionSources = const {};
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        InvoicesRepository.instance.getInvoicesForCustomer(widget.customerId),
        _loadPayments(),
        _loadCollectionSources(),
      ]);
      if (!mounted) return;
      setState(() {
        _invoices = results[0] as List<InvoiceRecordModel>;
        _payments = results[1] as List<PaymentBreakdown>;
        _collectionSources = results[2] as Map<String, String?>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, error);
    }
  }

  /// The payment breakdown is an extra detail: if it cannot be loaded the
  /// invoices are still shown.
  Future<List<PaymentBreakdown>> _loadPayments() async {
    try {
      return await PaymentBreakdownRepository.instance
          .getForCustomer(widget.customerId);
    } catch (error) {
      if (kDebugMode)
        debugPrint('[CustomerStatement] breakdown failed: $error');
      return const [];
    }
  }

  Future<Map<String, String?>> _loadCollectionSources() async {
    try {
      return await PaymentBreakdownRepository.instance
          .getCollectionSourcesForCustomer(widget.customerId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CustomerStatement] collection sources failed: $error');
      }
      return const {};
    }
  }

  DateTime get _since =>
      monthsBefore(DateTime.now(), CustomerInvoicesScreen.recentMonths);

  /// Payments worth a row of their own: ones that collected old debt with no
  /// new invoice attached. A payment issued together with a new invoice is
  /// never shown here — its old-debt part, if any, is shown inside that
  /// invoice's own details instead, so the invoice appears only once.
  List<PaymentBreakdown> get _visiblePayments {
    return _payments.where((p) {
      final worthARow = p.ownInvoiceLines.isEmpty && p.oldDebtLines.isNotEmpty;
      if (!worthARow) return false;
      return _showAll || !p.collectedAt.toLocal().isBefore(_since);
    }).toList();
  }

  /// Total old debt collected together with each invoice's own payment,
  /// keyed by invoice code — so the list can show the combined amount the
  /// customer actually paid at that moment, not just the invoice's own price.
  Map<String, double> get _oldDebtByInvoiceCode {
    final map = <String, double>{};
    for (final p in _payments) {
      final code = p.ownInvoiceCode;
      if (code == null) continue;
      final oldDebt = p.oldDebtLines.fold(0.0, (sum, l) => sum + l.amount);
      if (oldDebt > 0) map[code] = oldDebt;
    }
    return map;
  }

  List<InvoiceRecordModel> get _visible {
    if (_showAll) return _invoices;
    final since =
        monthsBefore(DateTime.now(), CustomerInvoicesScreen.recentMonths);
    return _invoices.where((i) => !i.date.isBefore(since)).toList();
  }

  /// Invoices and payments merged, newest first inside and between months.
  Map<String, List<_StatementEntry>> _groupByMonth(
    List<InvoiceRecordModel> invoices,
    List<PaymentBreakdown> payments,
  ) {
    final entries = <_StatementEntry>[
      for (final i in invoices) _StatementEntry.invoice(i),
      for (final p in payments) _StatementEntry.payment(p),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final groups = <String, List<_StatementEntry>>{};
    for (final entry in entries) {
      final d = entry.date.toLocal();
      final key = '${_arabicMonths[d.month]} ${d.year}';
      groups.putIfAbsent(key, () => []).add(entry);
    }
    return groups;
  }

  void _openInvoice(String invoiceCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoiceCode: invoiceCode,
          customerName: widget.customerName,
          previousBalanceAtView: widget.currentBalance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visible = _visible;
    final visiblePayments = _visiblePayments;
    final groups = _groupByMonth(visible, visiblePayments);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('كشف حساب آخر 6 شهور'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        actions: [
          if (widget.onExportPdf != null)
            IconButton(
              tooltip: 'كشف الحساب PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: widget.onExportPdf,
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
            children: [
              Text(
                widget.customerName,
                style: AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 15.sp),
              ),
              SizedBox(height: 12.h),
              // Wrap (not Row): with a large font scale on a narrow phone the
              // two chips and the counter do not fit on one line.
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('آخر 6 شهور'),
                    selected: !_showAll,
                    onSelected: (_) => setState(() => _showAll = false),
                  ),
                  ChoiceChip(
                    label: const Text('كل الفواتير'),
                    selected: _showAll,
                    onSelected: (_) => setState(() => _showAll = true),
                  ),
                  if (!_loading)
                    Text(
                      '${visible.length} فاتورة',
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 11.sp),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              if (_loading)
                Padding(
                  padding: EdgeInsets.only(top: 60.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (visible.isEmpty && visiblePayments.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 60.h),
                  child: Center(
                    child: Text(
                      _showAll
                          ? 'لسه مفيش فواتير مسجلة للعميل ده'
                          : 'لا توجد فواتير خلال آخر 6 شهور',
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 12.sp),
                    ),
                  ),
                )
              else
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                    child: Text(
                      entry.key,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.primary, fontSize: 12.sp),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (final item in entry.value)
                          if (item.invoice != null)
                            _InvoiceRow(
                              invoice: item.invoice!,
                              oldDebtCollected:
                                  _oldDebtByInvoiceCode[item.invoice!.code] ??
                                      0,
                              hasOldDebtSource: _collectionSources
                                  .containsKey(item.invoice!.id),
                              collectedViaInvoiceCode:
                                  _collectionSources[item.invoice!.id],
                              onTap: () => _openInvoice(
                                _collectionSources[item.invoice!.id] ??
                                    item.invoice!.code,
                              ),
                            )
                          else
                            _PaymentRow(payment: item.payment!),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceRecordModel invoice;
  final VoidCallback onTap;

  /// Old debt collected together with this invoice's own payment, if any.
  /// Added to the amount shown on the card, so the card reflects what the
  /// customer actually paid at that moment — not just this invoice's price.
  final double oldDebtCollected;

  /// True when this invoice's own amount was settled (in full or in part) as
  /// old debt collected together with another payment, rather than paid on
  /// its own — so it gets a distinct "محصّلة" label instead of "مدفوعة".
  final bool hasOldDebtSource;

  /// The other invoice that carried this one's collection, if there is one
  /// to point to (tapping opens that invoice instead of this one).
  final String? collectedViaInvoiceCode;

  const _InvoiceRow({
    required this.invoice,
    required this.onTap,
    this.oldDebtCollected = 0,
    this.hasOldDebtSource = false,
    this.collectedViaInvoiceCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settledElsewhere =
        hasOldDebtSource && invoice.status == InvoiceStatus.paid;
    final statusColor = settledElsewhere
        ? colors.statOrange
        : switch (invoice.status) {
            InvoiceStatus.paid => colors.primary,
            InvoiceStatus.partial => colors.statOrange,
            InvoiceStatus.deferred => colors.statusNotReached,
          };
    final statusLabel = settledElsewhere ? 'محصّلة' : invoice.status.label;
    final d = invoice.date;
    final dateLabel =
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final hasOldDebt = oldDebtCollected > 0;
    final totalWithOldDebt = invoice.amount + oldDebtCollected;

    final subtitle = hasOldDebt
        ? '$dateLabel  •  شامل دين قديم'
        : settledElsewhere && collectedViaInvoiceCode != null
            ? 'اتحصّلت مع الفاتورة $collectedViaInvoiceCode'
            : dateLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: colors.textMuted, size: 18.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.code,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 12.sp),
                      ),
                      if (invoice.isFromAdmin) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'من الإدارة',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                                color: colors.primary, fontSize: 9.sp),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Text(
              '${totalWithOldDebt.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 12.sp),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: statusColor, fontSize: 10.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of the statement: either an invoice or a payment.
class _StatementEntry {
  final InvoiceRecordModel? invoice;
  final PaymentBreakdown? payment;

  const _StatementEntry.invoice(InvoiceRecordModel this.invoice)
      : payment = null;
  const _StatementEntry.payment(PaymentBreakdown this.payment) : invoice = null;

  DateTime get date => invoice?.date ?? payment!.collectedAt;
}

/// A payment. Collapsed it shows the whole amount the customer paid; tapping
/// it shows how that amount was split between the invoice issued with it and
/// the older invoices it collected.
class _PaymentRow extends StatefulWidget {
  final PaymentBreakdown payment;

  const _PaymentRow({required this.payment});

  @override
  State<_PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends State<_PaymentRow> {
  bool _expanded = false;

  static String _amount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final payment = widget.payment;
    final d = payment.collectedAt.toLocal();
    final dateLabel =
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final ownCode = payment.ownInvoiceCode;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.textMuted,
                  size: 18.sp,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.code,
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 12.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        ownCode == null
                            ? dateLabel
                            : '$dateLabel  •  مع الفاتورة $ownCode',
                        style: AppTextStyles.almaraiRegular14
                            .copyWith(color: colors.textMuted, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_amount(payment.total)} ج.م',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 12.sp),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'تحصيل',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.primary, fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (final line in payment.lines)
                  _BreakdownLine(line: line, amountText: _amount(line.amount)),
                Divider(color: colors.border, height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'إجمالي التحصيل',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: colors.text, fontSize: 11.sp),
                      ),
                    ),
                    Text(
                      '${_amount(payment.total)} ج.م',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.primary, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  final PaymentBreakdownLine line;
  final String amountText;

  const _BreakdownLine({required this.line, required this.amountText});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = line.isOwnInvoice ? 'دفعة الفاتورة' : 'دين قديم';
    final target = line.invoiceCode ?? 'رصيد سابق';
    final accent = line.isOwnInvoice ? colors.primary : colors.statOrange;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              kind,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: accent, fontSize: 9.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              target,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.text, fontSize: 11.sp),
            ),
          ),
          Text(
            '$amountText ج.م',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}
