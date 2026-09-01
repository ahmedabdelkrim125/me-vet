import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:printing/printing.dart';

import '../../../invoices/domain/invoice_pdf_builder.dart';
import '../data/invoices_repository.dart';


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
  bool _loading = true;
  bool _hasError = false;

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<Uint8List> _buildPdf(InvoiceFullDetail detail) {
    return InvoicePdfBuilder.build(
      InvoicePdfData(
        invoiceNumber: detail.code,
        date: detail.date,
        customerName: widget.customerName,
        repName: '',
        items: detail.items
            .map((i) => InvoicePdfLineItem(
                  name: i.productName,
                  quantity: i.quantity,
                  price: i.unitPrice,
                  total: i.lineTotal,
                ))
            .toList(),
        invoiceTotal: detail.totalAmount,
        previousBalance: widget.previousBalanceAtView,
        totalDue: detail.totalAmount + widget.previousBalanceAtView,
        paidNow: detail.paidNow,
        remaining: detail.remaining,
      ),
    );
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
      await Printing.sharePdf(bytes: bytes, filename: '${detail.code}.pdf');
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
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError || _detail == null
                      ? Center(
                          child: Text(
                            'تعذر تحميل تفاصيل الفاتورة',
                            style: AppTextStyles.almaraiRegular14
                                .copyWith(color: colors.textMuted),
                          ),
                        )
                      : _DetailBody(detail: _detail!),
            ),
            if (!_loading && _detail != null)
              _FooterActions(onPrint: _printPdf, onShare: _sharePdf),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String code;
  final VoidCallback onBack;

  const _Header({required this.code, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(CupertinoIcons.back,
                color: colors.primary, size: 22.sp),
          ),
          Text(
            'تفاصيل الفاتورة $code',
            style: AppTextStyles.cairoBold18
                .copyWith(color: colors.primary, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final InvoiceFullDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        _InfoCard(
          children: [
            _InfoRow(
                label: 'التاريخ',
                value:
                    '${detail.date.year}/${detail.date.month.toString().padLeft(2, '0')}/${detail.date.day.toString().padLeft(2, '0')}'),
            _InfoRow(label: 'نوع البيع', value: detail.saleType),
            _InfoRow(label: 'الحالة', value: detail.statusLabel),
          ],
        ),
        SizedBox(height: 16.h),
        Text('المنتجات',
            style: AppTextStyles.cairoMedium16
                .copyWith(color: colors.text, fontSize: 13.sp)),
        SizedBox(height: 8.h),
        for (final item in detail.items) _ItemRow(item: item),
        SizedBox(height: 16.h),
        _InfoCard(
          children: [
            _InfoRow(
                label: 'الإجمالي قبل الخصم',
                value: '${detail.subtotal.toStringAsFixed(0)} ج.م'),
            if (detail.discountPercent > 0)
              _InfoRow(
                  label: 'الخصم',
                  value: '${detail.discountPercent.toStringAsFixed(0)}%'),
            _InfoRow(
                label: 'الإجمالي',
                value: '${detail.totalAmount.toStringAsFixed(0)} ج.م',
                highlight: true),
            _InfoRow(
                label: 'المدفوع',
                value: '${detail.paidNow.toStringAsFixed(0)} ج.م'),
            _InfoRow(
                label: 'المتبقي',
                value: '${detail.remaining.toStringAsFixed(0)} ج.م'),
          ],
        ),
        if (detail.notes != null && detail.notes!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _InfoCard(
            children: [
              _InfoRow(label: 'ملاحظات', value: detail.notes!),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                Text(item.productName,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          Text('${item.lineTotal.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoBold18
                  .copyWith(color: colors.primary, fontSize: 13.sp)),
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
        children: [
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 12.sp)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: highlight ? colors.primary : colors.text,
                fontSize: highlight ? 14.sp : 12.sp,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _FooterActions({required this.onPrint, required this.onShare});

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
                  backgroundColor: const Color(0xFF25D366)),
              icon: const FaIcon(FontAwesomeIcons.whatsapp,
                  color: Colors.white, size: 18),
              label: const Text('مشاركة PDF',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
