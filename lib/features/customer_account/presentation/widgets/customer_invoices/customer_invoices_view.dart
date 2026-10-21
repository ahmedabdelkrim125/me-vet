import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_cubit.dart';
import 'package:mivet_app/features/customer_account/presentation/cubit/customer_invoices_state.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/statement_filter_chips.dart';
import 'package:mivet_app/features/customer_account/presentation/widgets/customer_invoices/statement_groups.dart';
import 'package:mivet_app/features/invoices/presentation/screens/invoice_detail_screen.dart';

class CustomerInvoicesView extends StatelessWidget {
  final String customerName;
  final double currentBalance;
  final VoidCallback? onExportPdf;

  const CustomerInvoicesView({
    super.key,
    required this.customerName,
    required this.currentBalance,
    required this.onExportPdf,
  });

  void _openInvoice(BuildContext context, String invoiceCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoiceCode: invoiceCode,
          customerName: customerName,
          previousBalanceAtView: currentBalance,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomerInvoicesState state) {
    final colors = context.colors;
    if (state.loading) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.visibleInvoices.isEmpty && state.visiblePayments.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: Center(
          child: Text(
            state.showAll
                ? 'لسه مفيش فواتير مسجلة للعميل ده'
                : 'لا توجد فواتير خلال آخر 6 شهور',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 12.sp),
          ),
        ),
      );
    }
    return StatementGroups(
      state: state,
      onOpenInvoice: (code) => _openInvoice(context, code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<CustomerInvoicesCubit>();

    return BlocListener<CustomerInvoicesCubit, CustomerInvoicesState>(
      listenWhen: (previous, current) => current.error != null,
      listener: (context, state) => showAppError(context, state.error!),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('كشف حساب آخر 6 شهور'),
          backgroundColor: colors.surface,
          foregroundColor: colors.primary,
          actions: [
            if (onExportPdf != null)
              IconButton(
                tooltip: 'كشف الحساب PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: onExportPdf,
              ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
              children: [
                Text(
                  customerName,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.text, fontSize: 15.sp),
                ),
                SizedBox(height: 12.h),
                const StatementFilterChips(),
                SizedBox(height: 8.h),
                BlocBuilder<CustomerInvoicesCubit, CustomerInvoicesState>(
                  builder: _buildBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
