import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

import '../../auth/domain/models/user_profile.dart';
import '../data/admin_actions_service.dart';

/// أداء مندوب واحد بالتفصيل: زياراته، فواتيره، مبيعاته، تحصيلاته، ومرتجعاته.
///
/// البيانات كلها بتيجي من RPC واحدة (`get_rep_performance_stats`) بترجع
/// صف لكل المناديب مرة واحدة، فبنجيبها كاملة ونفلتر على المندوب المطلوب —
/// أبسط من عمل RPC تاني لمندوب واحد، والفرق في الأداء غير محسوس هنا.
class RepPerformanceScreen extends StatefulWidget {
  final UserProfile rep;

  const RepPerformanceScreen({super.key, required this.rep});

  @override
  State<RepPerformanceScreen> createState() => _RepPerformanceScreenState();
}

class _RepPerformanceScreenState extends State<RepPerformanceScreen> {
  final _service = AdminActionsService();
  RepPerformanceStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _service.getRepPerformanceStats();
      final mine = all.where((s) => s.repId == widget.rep.id);
      if (!mounted) return;
      setState(() {
        _stats = mine.isEmpty ? null : mine.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.rep.name,
          style: AppTextStyles.cairoBold18
              .copyWith(color: Colors.white, fontSize: 17.sp),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? Center(
                  child: Text(
                    'لا توجد بيانات كافية لهذا المندوب بعد',
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: AppColors.navInactive, fontSize: 13.sp),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      const _SectionTitle('الزيارات'),
                      _StatsGrid(items: [
                        _Stat('عملاء مسندين', '${stats.assignedCustomers}'),
                        _Stat('عملاء تمت زيارتهم', '${stats.visitedCustomers}'),
                        _Stat('إجمالي الزيارات', '${stats.visitCount}'),
                        _Stat('تمت', '${stats.completedVisits}'),
                        _Stat('بيع', '${stats.soldVisits}'),
                        _Stat('بدون طلب', '${stats.noOrderVisits}'),
                        _Stat('لم يوصل', '${stats.notReachedVisits}',
                            isWarning: stats.notReachedVisits > 0),
                        _Stat('متبقية', '${stats.pendingVisits}'),
                      ]),
                      SizedBox(height: 18.h),
                      const _SectionTitle('الفواتير والمبيعات'),
                      _StatsGrid(items: [
                        _Stat('عملاء لهم فواتير', '${stats.customersWithInvoices}'),
                        _Stat('عدد الفواتير', '${stats.invoiceCount}'),
                        _Stat('إجمالي المبيعات', _money(stats.totalSales)),
                        _Stat('عدد الوحدات المباعة', '${stats.totalUnitsSold}'),
                        _Stat('مديونية ناتجة عن فواتيره',
                            _money(stats.outstandingInvoiceAmount),
                            isWarning: stats.outstandingInvoiceAmount > 0),
                      ]),
                      SizedBox(height: 18.h),
                      const _SectionTitle('التحصيلات والمرتجعات'),
                      _StatsGrid(items: [
                        _Stat('إجمالي التحصيلات', _money(stats.totalCollections)),
                        _Stat('عدد المرتجعات', '${stats.returnCount}'),
                        _Stat('قيمة المرتجعات', _money(stats.totalReturns)),
                        _Stat('إجمالي المصروفات', _money(stats.totalExpenses)),
                      ]),
                      SizedBox(height: 18.h),
                      const _SectionTitle('الحالة'),
                      _StatsGrid(items: [
                        _Stat('حالة الحساب', stats.isActive ? 'نشط' : 'معطل'),
                        _Stat('آخر دخول', stats.lastLoginAt == null
                            ? '—'
                            : _dateTime(stats.lastLoginAt!)),
                      ]),
                    ],
                  ),
                ),
    );
  }

  static String _money(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)} ج.م';

  static String _dateTime(DateTime d) {
    final local = d.toLocal();
    final date =
        '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$date - ${hour12.toString().padLeft(2, '0')}:$minute ${local.hour < 12 ? 'ص' : 'م'}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: AppTextStyles.cairoBold18
            .copyWith(color: AppColors.primary, fontSize: 15.sp),
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final bool isWarning;
  const _Stat(this.label, this.value, {this.isWarning = false});
}

class _StatsGrid extends StatelessWidget {
  final List<_Stat> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: items.map((s) {
        final color =
            s.isWarning ? AppColors.statusNotReached : AppColors.primary;
        return Container(
          width: (MediaQuery.of(context).size.width - 32.w - 10.w) / 2,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.label,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: AppColors.navInactive, fontSize: 11.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                s.value,
                style: AppTextStyles.cairoBold18
                    .copyWith(color: color, fontSize: 16.sp),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
