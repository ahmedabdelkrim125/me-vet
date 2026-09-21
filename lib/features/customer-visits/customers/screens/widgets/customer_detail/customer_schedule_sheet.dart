import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../data/visits_repository.dart';

const List<String> _dbWeekdayNames = [
  'الأحد',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

Future<void> showCustomerScheduleSheet(
  BuildContext context, {
  required String customerId,
  required String customerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CustomerScheduleSheet(
      customerId: customerId,
      customerName: customerName,
    ),
  );
}

class _CustomerScheduleSheet extends StatefulWidget {
  final String customerId;
  final String customerName;

  const _CustomerScheduleSheet({
    required this.customerId,
    required this.customerName,
  });

  @override
  State<_CustomerScheduleSheet> createState() => _CustomerScheduleSheetState();
}

class _CustomerScheduleSheetState extends State<_CustomerScheduleSheet> {
  List<ScheduleRow> _schedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await VisitsRepository.instance
          .getScheduleForCustomer(widget.customerId);
      if (!mounted) return;
      setState(() {
        _schedule = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  bool _hasDay(int weekday) => _schedule.any((s) => s.weekday == weekday);

  Future<void> _toggleDay(int weekday) async {
    try {
      if (_hasDay(weekday)) {
        final row = _schedule.firstWhere((s) => s.weekday == weekday);
        await VisitsRepository.instance.removeSchedule(row.id);
      } else {
        await VisitsRepository.instance.addSchedule(
          customerId: widget.customerId,
          weekday: weekday,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'مواعيد الزيارة الثابتة',
            style: AppTextStyles.cairoBold18
                .copyWith(color: colors.text, fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'اختار الأيام اللي بتزور فيها "${widget.customerName}" بانتظام',
            style: AppTextStyles.almaraiRegular14
                .copyWith(color: colors.textMuted, fontSize: 11.sp),
          ),
          SizedBox(height: 16.h),
          if (_loading)
            Padding(
              padding: EdgeInsets.all(24.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else
            for (int weekday = 0; weekday < 7; weekday++)
              _DayRow(
                name: _dbWeekdayNames[weekday],
                selected: _hasDay(weekday),
                onTap: () => _toggleDay(weekday),
              ),
        ],
      )),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _DayRow({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: selected ? colors.primary.withOpacity(0.1) : colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.textMuted,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  name,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: selected ? colors.primary : colors.text,
                    fontSize: 13.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
