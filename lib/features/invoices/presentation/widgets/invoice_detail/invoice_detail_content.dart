import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_cubit.dart';
import 'package:mivet_app/features/invoices/presentation/cubit/invoice_detail_state.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_actions.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/invoice_detail/invoice_detail_body.dart';

class InvoiceDetailContent extends StatelessWidget {
  const InvoiceDetailContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<InvoiceDetailCubit, InvoiceDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final detail = state.detail;
        if (state.status == InvoiceDetailStatus.failure || detail == null) {
          return Center(
            child: Text(
              'تعذر تحميل تفاصيل الفاتورة',
              style: AppTextStyles.almaraiRegular14.copyWith(
                color: colors.textMuted,
              ),
            ),
          );
        }
        return InvoiceDetailBody(
          detail: detail,
          oldDebtLines: state.oldDebtLines,
          applicableCredit: state.applicableCredit,
          onCollectPayment: () => collectInvoicePayment(context),
          onAdjustOverpayment: () => adjustInvoiceOverpayment(context),
          onApplyCredit: () => applyInvoiceCredit(context),
        );
      },
    );
  }
}
