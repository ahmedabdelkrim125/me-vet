import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/home/domain/models/quick_invoice_models.dart';
import 'package:mivet_app/features/home/presentation/cubit/customer_picker_cubit.dart';
import 'package:mivet_app/features/home/presentation/cubit/customer_picker_state.dart';
import 'package:mivet_app/features/home/presentation/widgets/quick_invoice/invoice_bottom_sheet_shell.dart';

class CustomerPickerSheet extends StatelessWidget {
  final List<InvoiceCustomerModel> customers;

  const CustomerPickerSheet({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerPickerCubit(customers),
      child: const _CustomerPickerContent(),
    );
  }
}

class _CustomerPickerContent extends StatelessWidget {
  const _CustomerPickerContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InvoiceBottomSheetShell(
      title: 'اختر العميل',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: context.read<CustomerPickerCubit>().search,
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث باسم العميل...',
              hintStyle: TextStyle(color: colors.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20.sp, color: colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            ),
          ),
          SizedBox(height: 12.h),
          BlocBuilder<CustomerPickerCubit, CustomerPickerState>(
            builder: (context, state) {
              final filtered = state.filtered;
              return Column(
                children: [
                  ...filtered.map(
                    (c) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Material(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.pop(context, c),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 38.w,
                                  height: 38.w,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(Icons.storefront_outlined,
                                      color: colors.primary, size: 18.sp),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.customer.name,
                                        style: AppTextStyles.cairoMedium16.copyWith(
                                          color: colors.text,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        c.customer.address,
                                        style: AppTextStyles.almaraiRegular14.copyWith(
                                          color: colors.textMuted,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_left_rounded,
                                    color: colors.textMuted, size: 18.sp),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          'لا يوجد عملاء مطابقين للبحث',
                          style: AppTextStyles.almaraiRegular14
                              .copyWith(color: colors.textMuted),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
