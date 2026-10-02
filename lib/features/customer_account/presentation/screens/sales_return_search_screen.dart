import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/di/service_locator.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

import '../../domain/entities/invoice_product_search_result.dart';
import '../cubit/customer_account_cubit.dart';
import 'sales_return_screen.dart';

/// بحث عن منتج عشان تعمل مرتجع بيع من غير ما تحتاج تعرف العميل أو رقم
/// الفاتورة الأول — بيدوّر في فواتير كل العملاء اللي عندك صلاحية عليهم.
class SalesReturnSearchScreen extends StatefulWidget {
  const SalesReturnSearchScreen({super.key});

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
          await InvoicesRepository.instance.searchInvoicesByProduct(value);
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

  Future<void> _openResult(InvoiceProductSearchResult result) async {
    final cubit = sl<CustomerAccountCubit>()
      ..init(customerId: result.customerId, customerName: result.customerName);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SalesReturnScreen(
            customerId: result.customerId,
            customerName: result.customerName,
            initialInvoiceCode: result.invoiceCode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('بحث مرتجع بالمنتج'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
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
          'ابحث باسم المنتج عشان تشوف الفواتير اللي فيها',
          style: AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'مفيش فواتير فيها المنتج ده لسه قابلة للإرجاع',
          style: AppTextStyles.almaraiRegular14.copyWith(color: colors.textMuted),
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
              '${r.productName}  •  ${r.customerName}',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 13.sp),
            ),
            subtitle: Text(
              'فاتورة ${r.invoiceCode}  —  $dateLabel\n'
              'الكمية: ${r.quantity}'
              '${r.returnedQuantity > 0 ? ' (مرتجع منها ${r.returnedQuantity} بالفعل)' : ''}',
            ),
            isThreeLine: r.returnedQuantity > 0,
            trailing: const Icon(Icons.chevron_left),
          ),
        );
      },
    );
  }
}
