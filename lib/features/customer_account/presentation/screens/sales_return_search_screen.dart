import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

import '../../domain/entities/invoice_product_search_result.dart';

class SalesReturnSearchScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const SalesReturnSearchScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<SalesReturnSearchScreen> createState() =>
      _SalesReturnSearchScreenState();
}

class _SalesReturnSearchScreenState extends State<SalesReturnSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<InvoiceProductSearchResult> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final results =
          await InvoicesRepository.instance.searchCustomerInvoiceItems(
        customerId: widget.customerId,
        customerName: widget.customerName,
        query: value,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  void _openResult(InvoiceProductSearchResult result) {
    Navigator.of(context).pop(result.invoiceCode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('بحث في فواتير ${widget.customerName}',
            style: AppTextStyles.cairoBold18.copyWith(color: colors.text)),
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        iconTheme: IconThemeData(color: colors.text),
        actionsIconTheme: IconThemeData(color: colors.text),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'اكتب اسم المنتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_searched) {
      return Center(
        child: Text(
          'ابحث باسم المنتج عشان تشوف فواتير العميل اللي فيها',
          style:
              AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'مفيش فواتير للعميل ده فيها المنتج ده',
          style:
              AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _results.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final r = _results[index];
        final d = r.invoiceDate;
        final dateLabel =
            '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

        return Card(
          child: ListTile(
            onTap: () => _openResult(r),
            title: Text(
              r.productName,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 13.sp),
            ),
            subtitle: Text(
              'فاتورة ${r.invoiceCode}  —  $dateLabel\n'
              'الكمية: ${r.quantity}  —  السعر: ${r.unitPrice.toStringAsFixed(0)} ج.م',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_left),
          ),
        );
      },
    );
  }
}