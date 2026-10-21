import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_cubit.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_state.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/widgets/historical_invoice/historical_invoice_form.dart';

class HistoricalInvoiceView extends StatelessWidget {
  final String customerName;

  const HistoricalInvoiceView({super.key, required this.customerName});

  void _handleNotice(BuildContext context, HistoricalInvoiceState state) {
    final info = state.info;
    if (info != null) showAppInfo(context, info);
    final error = state.error;
    if (error != null) showAppError(context, error);
    if (state.submitted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<HistoricalInvoiceCubit>();

    return BlocListener<HistoricalInvoiceCubit, HistoricalInvoiceState>(
      listenWhen: (previous, current) =>
          current.info != null || current.error != null || current.submitted,
      listener: _handleNotice,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            'فاتورة تاريخية — $customerName',
            style: AppTextStyles.cairoBold18
                .copyWith(color: Colors.white, fontSize: 15.sp),
          ),
        ),
        body: const HistoricalInvoiceForm(),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: BlocSelector<HistoricalInvoiceCubit, HistoricalInvoiceState,
                bool>(
              selector: (state) => state.submitting,
              builder: (context, submitting) => ElevatedButton(
                onPressed: submitting ? null : cubit.submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: submitting
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'حفظ الفاتورة التاريخية',
                        style: AppTextStyles.cairoMedium16
                            .copyWith(color: Colors.white, fontSize: 14.sp),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
