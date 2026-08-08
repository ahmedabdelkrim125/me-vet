import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
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
  late final List<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = [...widget.initiallySelectedIds];
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

  void _confirm() {
    final customers = MockCustomersRepository.instance.customers;
    final selected = [
      for (final id in _selectedIds) customers.firstWhere((c) => c.id == id),
    ];
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final customers = MockCustomersRepository.instance.customers
        .where((c) => _query.isEmpty || c.name.contains(_query))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Text('حدد عملاء اليوم',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: AppColors.primary, fontSize: 15.sp)),
              SizedBox(height: 4.h),
              Text(
                '${_selectedIds.length} عميل متحدد',
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: AppColors.navInactive, fontSize: 11.sp),
              ),
              SizedBox(height: 12.h),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                textAlign: TextAlign.right,
                style: AppTextStyles.cairoRegular14
                    .copyWith(color: AppColors.primary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'ابحث عن عميل',
                  hintStyle: AppTextStyles.almaraiRegular14
                      .copyWith(color: AppColors.navInactive, fontSize: 12.sp),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final isSelected = _selectedIds.contains(customer.id);
                    return GestureDetector(
                      onTap: () => _toggle(customer.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGreen.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.navInactive,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.name,
                                      style: AppTextStyles.cairoMedium16
                                          .copyWith(
                                              color: AppColors.primary,
                                              fontSize: 12.sp)),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${customer.category} — ${customer.area}',
                                    style: AppTextStyles.almaraiRegular14
                                        .copyWith(
                                            color: AppColors.navInactive,
                                            fontSize: 10.sp),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Material(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: _selectedIds.isEmpty ? null : _confirm,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: Text(
                      'تأكيد خط اليوم',
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: Colors.white, fontSize: 14.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
