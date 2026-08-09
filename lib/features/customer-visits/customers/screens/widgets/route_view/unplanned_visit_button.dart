import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/customer_model.dart';

class UnplannedVisitButton extends StatelessWidget {
  final ValueChanged<CustomerModel> onCustomerSelected;
  final List<String> excludeIds;

  const UnplannedVisitButton({
    super.key,
    required this.onCustomerSelected,
    required this.excludeIds,
  });

  Future<void> _openSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UnplannedVisitSheet(excludeIds: excludeIds),
    );
    if (selected != null) onCustomerSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _openSheet(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'إضافة زيارة غير مخططة',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: context.colors.primary, fontSize: 13.sp),
                ),
              ),
              Container(
                width: 26.w,
                height: 26.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnplannedVisitSheet extends StatefulWidget {
  final List<String> excludeIds;

  const _UnplannedVisitSheet({required this.excludeIds});

  @override
  State<_UnplannedVisitSheet> createState() => _UnplannedVisitSheetState();
}

class _UnplannedVisitSheetState extends State<_UnplannedVisitSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customers = MockCustomersRepository.instance.customers
        .where((c) => !widget.excludeIds.contains(c.id))
        .where((c) =>
            _query.isEmpty ||
            c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 520.h),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'إضافة زيارة غير مخططة',
            style: AppTextStyles.cairoBold18
                .copyWith(color: context.colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 14.h),
          Container(
            height: 46.h,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: context.colors.border),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              textAlign: TextAlign.right,
              style: AppTextStyles.cairoRegular14
                  .copyWith(color: context.colors.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'ابحث عن عميل',
                hintStyle: AppTextStyles.almaraiRegular14
                    .copyWith(color: context.colors.textMuted, fontSize: 12.sp),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(13.w),
                  child: Icon(CupertinoIcons.search,
                      size: 16.sp, color: context.colors.textMuted),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Flexible(
            child: customers.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    child: Center(
                      child: Text(
                        'كل عملاءك موجودين في خط اليوم بالفعل',
                        style: AppTextStyles.cairoMedium16.copyWith(
                            color: context.colors.textMuted, fontSize: 12.sp),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Material(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () => Navigator.of(context).pop(customer),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(color: context.colors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(customer.name,
                                          style: AppTextStyles.cairoMedium16
                                              .copyWith(
                                                  color: context.colors.text,
                                                  fontSize: 13.sp)),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${customer.category} — ${customer.area}',
                                        style: AppTextStyles.almaraiRegular14
                                            .copyWith(
                                                color: context.colors.textMuted,
                                                fontSize: 11.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedAddCircle,
                                  size: 18.sp,
                                  color: context.colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
