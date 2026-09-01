import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../domain/models/customer_detail_model.dart';
import '../../invoice_detail_screen.dart';

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

class CustomerAccountStatementSection extends StatefulWidget {
  final List<InvoiceSummaryModel> recentInvoices;
  final List<InvoiceSummaryModel> allInvoices;
  final String customerName;
  final double currentBalance;
  final bool isLoading;

  const CustomerAccountStatementSection({
    super.key,
    required this.recentInvoices,
    required this.allInvoices,
    required this.customerName,
    this.currentBalance = 0,
    this.isLoading = false,
  });

  @override
  State<CustomerAccountStatementSection> createState() =>
      _CustomerAccountStatementSectionState();
}

class _CustomerAccountStatementSectionState
    extends State<CustomerAccountStatementSection> {
  bool _showAll = false;

  static final _skeletonInvoices = [
    InvoiceSummaryModel(
        code: 'INV-0000', date: DateTime.now(), amount: 0, status: 'مدفوعة'),
    InvoiceSummaryModel(
        code: 'INV-0000', date: DateTime.now(), amount: 0, status: 'جزئي'),
  ];

  Map<String, List<InvoiceSummaryModel>> _groupByMonth(
      List<InvoiceSummaryModel> invoices) {
    final map = <String, List<InvoiceSummaryModel>>{};
    for (final inv in invoices) {
      final key = '${_arabicMonths[inv.date.month]} ${inv.date.year}';
      map.putIfAbsent(key, () => []).add(inv);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final source = _showAll ? widget.allInvoices : widget.recentInvoices;
    final grouped = _groupByMonth(source);
    final hasMore = widget.allInvoices.length > widget.recentInvoices.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _showAll ? 'كل الفواتير' : 'كشف الحساب (آخر 6 شهور)',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: colors.text, fontSize: 13.sp),
              ),
              const Spacer(),
              if (hasMore && !widget.isLoading)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? 'آخر 6 شهور' : 'عرض الكل',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.primary, fontSize: 11.sp),
                  ),
                ),
            ],
          ),
          if (widget.isLoading)
            Skeletonizer(
              enabled: true,
              child: Column(
                children: [
                  for (final inv in _skeletonInvoices)
                    _InvoiceRow(invoice: inv, colors: colors),
                ],
              ),
            )
          else if (source.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                'لسه مفيش فواتير مسجلة للعميل ده',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 11.sp),
              ),
            )
          else
            for (final entry in grouped.entries) ...[
              Padding(
                padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                child: Text(
                  entry.key,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.primary, fontSize: 11.sp),
                ),
              ),
              for (final invoice in entry.value)
                _InvoiceRow(
                  invoice: invoice,
                  colors: colors,
                  customerName: widget.customerName,
                  currentBalance: widget.currentBalance,
                ),
            ],
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceSummaryModel invoice;
  final AppColorScheme colors;
  final String customerName;
  final double currentBalance;

  const _InvoiceRow({
    required this.invoice,
    required this.colors,
    this.customerName = '',
    this.currentBalance = 0,
  });

  Color get _statusColor {
    switch (invoice.status) {
      case 'مدفوعة':
        return colors.primary;
      case 'جزئي':
        return colors.statOrange;
      default:
        return colors.statusNotReached;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(
            invoiceCode: invoice.code,
            customerName: customerName,
            previousBalanceAtView: currentBalance,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: colors.textMuted, size: 18.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.code,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: colors.text, fontSize: 12.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    '${invoice.date.year}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.day.toString().padLeft(2, '0')}',
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Text('${invoice.amount.toStringAsFixed(0)} ج.م',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: colors.text, fontSize: 12.sp)),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(invoice.status,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: _statusColor, fontSize: 10.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
