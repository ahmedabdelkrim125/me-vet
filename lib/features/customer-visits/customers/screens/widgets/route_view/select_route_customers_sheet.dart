import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../domain/mock_customers_repository.dart';
import '../../../domain/models/customer_model.dart';

Future<List<CustomerModel>?> showSelectRouteCustomersSheet(
  BuildContext context, {
  required List<String> initiallySelectedIds,
}) {
  return showModalBottomSheet<List<CustomerModel>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _SelectRouteCustomersSheet(initiallySelectedIds: initiallySelectedIds),
  );
}

class _SelectRouteCustomersSheet extends StatefulWidget {
  final List<String> initiallySelectedIds;

  const _SelectRouteCustomersSheet({required this.initiallySelectedIds});

  @override
  State<_SelectRouteCustomersSheet> createState() =>
      _SelectRouteCustomersSheetState();
}

class _SelectRouteCustomersSheetState
    extends State<_SelectRouteCustomersSheet> {
  late final Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelectedIds.toSet();
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCustomers = MockCustomersRepository.instance.customers
        .where((c) =>
            _query.isEmpty ||
            c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 620.h),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'تعديل خط اليوم',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: context.colors.text, fontSize: 16.sp),
                ),
              ),
              Text(
                '${_selectedIds.length} محدد',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.primary, fontSize: 12.sp),
              ),
            ],
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
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allCustomers.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final customer = allCustomers[index];
                final isSelected = _selectedIds.contains(customer.id);
                return Material(
                  color: isSelected
                      ? context.colors.primary.withOpacity(0.08)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _toggle(customer.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22.w,
                            height: 22.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? context.colors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.textMuted,
                                width: 1.4,
                              ),
                            ),
                            child: isSelected
                                ? HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle02,
                                    size: 13.sp,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                    style: AppTextStyles.cairoMedium16.copyWith(
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14.h),
          Material(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                final selected = MockCustomersRepository.instance.customers
                    .where((c) => _selectedIds.contains(c.id))
                    .toList();
                Navigator.of(context).pop(selected);
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Text(
                  'حفظ خط اليوم',
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
