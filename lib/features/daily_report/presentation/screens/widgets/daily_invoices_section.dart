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
import 'package:mivet_app/core/utils/pdf_export.dart';

class DailyInvoicesSection extends StatefulWidget {
  const DailyInvoicesSection({super.key});

  @override
  State<DailyInvoicesSection> createState() => _DailyInvoicesSectionState();
}

class _DailyInvoicesSectionState extends State<DailyInvoicesSection> {
  List<DailyInvoiceSummary> _invoices = const [];
  bool _loading = true;
  bool _sharing = false;

  late final DateTime _from;
  late final DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = _from.add(const Duration(days: 1));
    _load();
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

  Future<double> _previousBalanceOf(String invoiceId) async {
    try {
      final balance =
          await InvoicesRepository.instance.getBalanceBeforeInvoice(invoiceId);
      return balance ?? 0;
    } catch (_) {
      return 0;
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
    double previousBalance,
  ) {
    final invoiceRemaining = detail.remaining < 0 ? 0.0 : detail.remaining;
    final accountRemaining = previousBalance + invoiceRemaining;
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
      paidNow: detail.paidNow,
      remaining: accountRemaining < 0 ? 0 : accountRemaining,
    );
  }

  Future<void> _shareAll() async {
    if (_invoices.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      final entries = <DailyInvoicePdfEntry>[];
      for (final invoice in _invoices) {
        final detail = await InvoicesRepository.instance
            .getInvoiceDetailByCode(invoice.code);
        final previousBalance = await _previousBalanceOf(invoice.id);
        entries.add(
          DailyInvoicePdfEntry(
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
            summary: _summaryOf(invoice, detail, previousBalance),
          ),
        );
      }

      final bytes = await DailyInvoicesPdfBuilder.build(entries, _from);
      if (!mounted) return;
      await PdfExport.share(
        bytes,
        'daily-invoices-${_from.year}-${_from.month}-${_from.day}.pdf',
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
                child: Text('الفواتير اليومية',
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
                  label: const Text('مشاركة الفواتير اليومية'),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_invoices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text('لسه مفيش فواتير النهاردة',
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