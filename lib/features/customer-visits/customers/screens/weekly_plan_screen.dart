import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../data/customers_repository.dart';
import '../data/visits_repository.dart';
import '../domain/models/customer_model.dart';

const List<String> _shortDayNames = [
  'أحد',
  'اثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
];

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  List<CustomerModel> _customers = [];
  Map<String, List<ScheduleRow>> _scheduleByCustomer = {};
  bool _loading = true;
  String _search = '';

  /// null = كل الأيام. 0 = الأحد ... 6 = السبت (نفس ترقيم weekday في الجدول).
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await CustomersRepository.instance.initialize();
      final schedule = await VisitsRepository.instance.getMySchedule();
      if (!mounted) return;
      final grouped = <String, List<ScheduleRow>>{};
      for (final row in schedule) {
        grouped.putIfAbsent(row.customerId, () => []).add(row);
      }
      setState(() {
        _customers = CustomersRepository.instance.customers;
        _scheduleByCustomer = grouped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  bool _customerHasDay(String customerId, int weekday) {
    return (_scheduleByCustomer[customerId] ?? [])
        .any((s) => s.weekday == weekday);
  }

  Future<void> _toggleDay(CustomerModel customer, int weekday) async {
    try {
      if (_customerHasDay(customer.id, weekday)) {
        final row = _scheduleByCustomer[customer.id]!
            .firstWhere((s) => s.weekday == weekday);
        await VisitsRepository.instance.removeSchedule(row.id);
      } else {
        await VisitsRepository.instance.addSchedule(
          customerId: customer.id,
          weekday: weekday,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  List<CustomerModel> get _filtered {
    final day = _selectedDay;
    var result = day == null
        ? _customers
        : _customers.where((c) => _customerHasDay(c.id, day)).toList();

    final q = _search.trim();
    if (q.isNotEmpty) {
      result = result.where((c) => c.name.contains(q) || c.phone.contains(q))
          .toList();
    }
    return result;
  }

  /// عدد العملاء المخططين ليوم معين، لعرضه على التاب.
  int _customerCountForDay(int weekday) =>
      _customers.where((c) => _customerHasDay(c.id, weekday)).length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            _DayFilterTabs(
              selectedDay: _selectedDay,
              customerCountForDay: _customerCountForDay,
              totalCustomers: _customers.length,
              onSelect: (day) => setState(() => _selectedDay = day),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: TextField(
                textAlign: TextAlign.right,
                onChanged: (v) => setState(() => _search = v),
                style:
                    AppTextStyles.cairoRegular14.copyWith(color: colors.text),
                decoration: InputDecoration(
                  hintText: 'ابحث عن عميل',
                  hintStyle: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 12.sp),
                  prefixIcon: Icon(CupertinoIcons.search,
                      size: 18.sp, color: colors.textMuted),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                              _selectedDay == null
                                  ? 'مفيش عملاء'
                                  : 'مفيش عملاء متخططين يوم ${_shortDayNames[_selectedDay!]}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                  color: colors.textMuted, fontSize: 13.sp)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final customer = _filtered[index];
                            return _CustomerPlanRow(
                              customer: customer,
                              isDaySelected: (wd) =>
                                  _customerHasDay(customer.id, wd),
                              onToggleDay: (wd) => _toggleDay(customer, wd),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 16.w, 14.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(CupertinoIcons.back, color: colors.primary, size: 22.sp),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تخطيط الأسبوع',
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.primary, fontSize: 16.sp)),
              SizedBox(height: 2.h),
              Text('حدد أيام الزيارة الثابتة لكل عميل',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayFilterTabs extends StatelessWidget {
  final int? selectedDay;
  final int Function(int weekday) customerCountForDay;
  final int totalCustomers;
  final void Function(int? day) onSelect;

  const _DayFilterTabs({
    required this.selectedDay,
    required this.customerCountForDay,
    required this.totalCustomers,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.only(bottom: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            _DayTab(
              label: 'كل العملاء',
              count: totalCustomers,
              selected: selectedDay == null,
              onTap: () => onSelect(null),
            ),
            for (int wd = 0; wd < 7; wd++) ...[
              SizedBox(width: 6.w),
              _DayTab(
                label: _shortDayNames[wd],
                count: customerCountForDay(wd),
                selected: selectedDay == wd,
                onTap: () => onSelect(wd),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _DayTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.cairoMedium16.copyWith(
                color: selected ? Colors.white : colors.text,
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: selected ? Colors.white : colors.primary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerPlanRow extends StatelessWidget {
  final CustomerModel customer;
  final bool Function(int weekday) isDaySelected;
  final void Function(int weekday) onToggleDay;

  const _CustomerPlanRow({
    required this.customer,
    required this.isDaySelected,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.name,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 13.sp)),
          SizedBox(height: 2.h),
          Text(customer.area,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: colors.textMuted, fontSize: 10.sp)),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (int wd = 0; wd < 7; wd++)
                _DayChip(
                  label: _shortDayNames[wd],
                  selected: isDaySelected(wd),
                  onTap: () => onToggleDay(wd),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.cairoMedium16.copyWith(
            color: selected ? Colors.white : colors.textMuted,
            fontSize: 11.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
