import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/months_before.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/invoice_record_model.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/invoice_detail_screen.dart';

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
      final invoices = await InvoicesRepository.instance
          .getInvoicesForCustomer(widget.customerId);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, error);
    }
  }

  List<InvoiceRecordModel> get _visible {
    if (_showAll) return _invoices;
    final since =
        monthsBefore(DateTime.now(), CustomerInvoicesScreen.recentMonths);
    return _invoices.where((i) => !i.date.isBefore(since)).toList();
  }

  /// Keeps the incoming order (newest first) inside and between months.
  Map<String, List<InvoiceRecordModel>> _groupByMonth(
    List<InvoiceRecordModel> invoices,
  ) {
    final groups = <String, List<InvoiceRecordModel>>{};
    for (final invoice in invoices) {
      final key = '${_arabicMonths[invoice.date.month]} ${invoice.date.year}';
      groups.putIfAbsent(key, () => []).add(invoice);
    }
    return groups;
  }

  void _openInvoice(InvoiceRecordModel invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoiceCode: invoice.code,
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
    final groups = _groupByMonth(visible);

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
              else if (visible.isEmpty)
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
                        for (final invoice in entry.value)
                          _InvoiceRow(
                            invoice: invoice,
                            onTap: () => _openInvoice(invoice),
                          ),
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

  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (invoice.status) {
      InvoiceStatus.paid => colors.primary,
      InvoiceStatus.partial => colors.statOrange,
      InvoiceStatus.deferred => colors.statusNotReached,
    };
    final d = invoice.date;
    final dateLabel =
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

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
                  Text(
                    invoice.code,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    dateLabel,
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Text(
              '${invoice.amount.toStringAsFixed(0)} ج.م',
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
                invoice.status.label,
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
