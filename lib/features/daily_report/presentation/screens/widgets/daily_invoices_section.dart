import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';
import 'package:mivet_app/features/invoices/domain/invoice_pdf_builder.dart';
import 'package:mivet_app/features/invoices/domain/models/invoice_record_model.dart';
import 'package:mivet_app/features/invoices/presentation/screens/invoice_detail_screen.dart';

import '../../../domain/daily_invoices_pdf_builder.dart';
import '../daily_invoices_by_date_screen.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';

class DailyInvoicesSection extends StatefulWidget {
  final DateTime? date;
  final bool showDateLink;

  const DailyInvoicesSection({
    super.key,
    this.date,
    this.showDateLink = true,
  });

  @override
  State<DailyInvoicesSection> createState() => _DailyInvoicesSectionState();
}

class _DailyInvoicesSectionState extends State<DailyInvoicesSection> {
  static const int _fetchBatchSize = 6;
  static const int _fetchAttempts = 3;

  List<DailyInvoiceSummary> _invoices = const [];
  bool _loading = true;
  bool _sharing = false;
  String? _progress;

  DateTime get _day {
    final source = widget.date ?? DateTime.now();
    return DateTime(source.year, source.month, source.day);
  }

  DateTime get _from => _day;

  DateTime get _to => DateTime(_day.year, _day.month, _day.day + 1);

  bool get _isToday {
    final now = DateTime.now();
    return _day.year == now.year &&
        _day.month == now.month &&
        _day.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DailyInvoicesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSource = oldWidget.date ?? DateTime.now();
    final oldDay = DateTime(oldSource.year, oldSource.month, oldSource.day);
    if (oldDay != _day) {
      setState(() {
        _loading = true;
        _invoices = const [];
      });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final invoices = await InvoicesRepository.instance
          .getDailyInvoiceSummaries(from: _from, to: _to);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  Future<InvoiceAccountSummary?> _accountSummaryOf(String invoiceId) async {
    try {
      return await InvoicesRepository.instance
          .getInvoiceAccountSummary(invoiceId);
    } catch (_) {
      return null;
    }
  }

  double _discountOf(InvoiceFullDetail detail) {
    final fromSubtotal = detail.subtotal - detail.totalAmount;
    return detail.discountAmount > fromSubtotal
        ? detail.discountAmount
        : (fromSubtotal > 0 ? fromSubtotal : 0.0);
  }

  InvoicePdfData _summaryOf(
    DailyInvoiceSummary invoice,
    InvoiceFullDetail detail,
    InvoiceAccountSummary? summary,
  ) {
    final previousBalance = summary?.previousBalance ?? 0.0;
    final accountRemaining = summary?.remaining ??
        previousBalance + (detail.remaining < 0 ? 0.0 : detail.remaining);
    return InvoicePdfData(
      invoiceNumber: detail.code,
      date: invoice.date,
      customerName: invoice.customerName,
      repName: '',
      items: const [],
      invoiceTotal: detail.totalAmount,
      discountAmount: _discountOf(detail),
      previousBalance: previousBalance,
      totalDue: detail.totalAmount + previousBalance,
      paidNow: summary?.totalPaid ?? detail.paidNow,
      remaining: accountRemaining < 0 ? 0 : accountRemaining,
    );
  }

  Future<InvoiceFullDetail> _detailWithRetry(String code) async {
    Object? lastError;
    for (var attempt = 0; attempt < _fetchAttempts; attempt++) {
      try {
        return await InvoicesRepository.instance.getInvoiceDetailByCode(code);
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('تعذر تحميل الفاتورة $code');
  }

  Future<DailyInvoicePdfEntry> _entryOf(DailyInvoiceSummary invoice) async {
    final detailFuture = _detailWithRetry(invoice.code);
    final summaryFuture = _accountSummaryOf(invoice.id);
    final detail = await detailFuture;
    final summary = await summaryFuture;
    return DailyInvoicePdfEntry(
      invoiceCode: detail.code,
      customerName: invoice.customerName,
      date: invoice.date,
      items: [
        for (final item in detail.items)
          (
            name: item.productName,
            quantity: item.quantity,
            price: item.unitPrice,
            total: item.lineTotal,
          ),
      ],
      total: detail.totalAmount,
      status: invoice.status.label,
      summary: _summaryOf(invoice, detail, summary),
    );
  }

  Future<List<DailyInvoicePdfEntry>> _collectEntries() async {
    final entries = <DailyInvoicePdfEntry>[];
    for (var start = 0; start < _invoices.length; start += _fetchBatchSize) {
      final slice = _invoices.skip(start).take(_fetchBatchSize).toList();
      final batch = await Future.wait(slice.map(_entryOf));
      entries.addAll(batch);
      if (mounted) {
        setState(
            () => _progress = 'تحميل ${entries.length}/${_invoices.length}');
      }
    }
    return entries;
  }

  String _fileBaseName() {
    final day = _day;
    return 'daily-invoices-${day.year}-${day.month}-${day.day}';
  }

  Future<void> _shareAll() async {
    if (_invoices.isEmpty || _sharing) return;
    setState(() {
      _sharing = true;
      _progress = 'تحميل 0/${_invoices.length}';
    });
    try {
      final entries = await _collectEntries();
      if (mounted) setState(() => _progress = 'تجهيز الملفات...');
      final parts = await DailyInvoicesPdfBuilder.buildParts(
        entries,
        _day,
        onProgress: (done, total) {
          if (mounted) setState(() => _progress = 'ملف $done/$total');
        },
      );
      if (!mounted) return;
      await PdfExport.shareMany(parts, _fileBaseName());
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
          _progress = null;
        });
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.receipt_long_outlined,
                    color: AppColors.primaryGreen, size: 20.w),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                    _isToday
                        ? 'الفواتير اليومية'
                        : 'فواتير يوم ${_formatDate(_day)}',
                    style: AppTextStyles.cairoBold18
                        .copyWith(fontSize: 16.sp, color: colors.text)),
              ),
              if (!_loading && _invoices.isNotEmpty)
                TextButton.icon(
                  onPressed: _sharing ? null : _shareAll,
                  icon: _sharing
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined, size: 16),
                  label: Text(_progress ?? 'مشاركة الفواتير اليومية'),
                ),
            ],
          ),
          if (widget.showDateLink)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DailyInvoicesByDateScreen(),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('فواتير يوم محدد'),
              ),
            ),
          SizedBox(height: 12.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_invoices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                    _isToday
                        ? 'لسه مفيش فواتير النهاردة'
                        : 'مفيش فواتير في اليوم ده',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoices.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.border.withOpacity(0.5), height: 16.h),
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvoiceDetailScreen(
                        invoiceCode: invoice.code,
                        customerName: invoice.customerName,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${invoice.code}  •  ${invoice.customerName}',
                              style: AppTextStyles.cairoMedium16.copyWith(
                                  fontSize: 13.sp, color: colors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${invoice.date.hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')}  •  ${invoice.status.label}',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                  fontSize: 10.sp, color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${invoice.amount.toStringAsFixed(0)} ج.م',
                        style: AppTextStyles.cairoBold18.copyWith(
                            fontSize: 13.sp, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
