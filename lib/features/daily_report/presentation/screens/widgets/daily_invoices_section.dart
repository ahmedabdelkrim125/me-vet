import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/presentation/screens/invoice_detail_screen.dart';

import '../../../../invoices/domain/models/invoice_record_model.dart';
import '../../cubit/daily_invoices_cubit.dart';
import '../../cubit/daily_invoices_state.dart';
import '../daily_invoices_by_date_screen.dart';

class DailyInvoicesSection extends StatelessWidget {
  final DateTime? date;
  final bool showDateLink;

  const DailyInvoicesSection({
    super.key,
    this.date,
    this.showDateLink = true,
  });

  DateTime get _day {
    final source = date ?? DateTime.now();
    return DateTime(source.year, source.month, source.day);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyInvoicesCubit>(
      key: ValueKey(_day),
      create: (_) => DailyInvoicesCubit(day: _day)..load(),
      child: _DailyInvoicesView(showDateLink: showDateLink),
    );
  }
}

class _DailyInvoicesView extends StatelessWidget {
  final bool showDateLink;

  const _DailyInvoicesView({required this.showDateLink});

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _openInvoice(
    BuildContext context,
    String code,
    String customerName,
  ) async {
    final cubit = context.read<DailyInvoicesCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(
          invoiceCode: code,
          customerName: customerName,
        ),
      ),
    );
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DailyInvoicesCubit>();

    return BlocConsumer<DailyInvoicesCubit, DailyInvoicesState>(
      listenWhen: (previous, current) => current.error != null,
      listener: (context, state) => showAppError(context, state.error!),
      builder: (context, state) => _buildCard(context, cubit, state),
    );
  }

  Widget _buildCard(
    BuildContext context,
    DailyInvoicesCubit cubit,
    DailyInvoicesState state,
  ) {
    final colors = context.colors;
    final day = cubit.day;
    final invoices = state.invoices;

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
                    cubit.isToday
                        ? 'الفواتير اليومية'
                        : 'فواتير يوم ${_formatDate(day)}',
                    style: AppTextStyles.cairoBold18
                        .copyWith(fontSize: 16.sp, color: colors.text)),
              ),
              if (!state.isLoading && invoices.isNotEmpty)
                TextButton.icon(
                  onPressed: state.sharing ? null : cubit.shareAll,
                  icon: state.sharing
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined, size: 16),
                  label: Text(state.progress ?? 'مشاركة الفواتير اليومية'),
                ),
            ],
          ),
          if (showDateLink)
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
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (invoices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                    cubit.isToday
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
              itemCount: invoices.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.border.withOpacity(0.5), height: 16.h),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return InkWell(
                  onTap: () => _openInvoice(
                    context,
                    invoice.code,
                    invoice.customerName,
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
