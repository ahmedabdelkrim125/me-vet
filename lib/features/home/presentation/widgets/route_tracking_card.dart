import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/customers_repository.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/route_stop_model.dart';
import 'package:mivet_app/features/customer-visits/customers/domain/models/visit_status.dart';
import 'package:mivet_app/features/customer-visits/customers/presentation/controllers/today_route_controller.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/customer_detail_screen.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/weekly_plan_screen.dart';
import 'package:mivet_app/features/customer-visits/customers/screens/widgets/route_view/route_status_style.dart';

/// Delivery-style tracking of today's customers route.
///
/// One step per customer, in route order:
///  * visited  (تمت / بيع / بدون طلب) — done, with the time it was recorded
///  * missed   (لم يوصل)              — the rep could not reach the customer
///  * current  (جاري الآن)            — the first customer not handled yet
///  * upcoming (قادم)                 — the rest
///
/// The statuses are changed from the route page (customers route tab); this
/// card only reflects them, live, through [TodayRouteController.stopsNotifier].
/// The list is replaced with the new day's customers at 12:00 AM.
class RouteTrackingCard extends StatelessWidget {
  const RouteTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<List<RouteStopModel>>(
      valueListenable: TodayRouteController.instance.stopsNotifier,
      builder: (context, stops, _) {
        final currentIndex =
            stops.indexWhere((s) => s.status == RouteVisitStatus.pending);
        final visited = stops.where(_isVisited).length;
        final missed =
            stops.where((s) => s.status == RouteVisitStatus.notReached).length;

        return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.subtleShadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(total: stops.length, visited: visited, missed: missed),
              SizedBox(height: 18.h),
              if (stops.isEmpty)
                const _EmptyState()
              else ...[
                if (currentIndex == -1) const _AllDoneBanner(),
                for (int i = 0; i < stops.length; i++)
                  _TrackingStep(
                    stop: stops[i],
                    number: i + 1,
                    state: _stateOf(stops[i], isCurrent: i == currentIndex),
                    isLast: i == stops.length - 1,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  static bool _isVisited(RouteStopModel stop) =>
      stop.status == RouteVisitStatus.completed ||
      stop.status == RouteVisitStatus.sold ||
      stop.status == RouteVisitStatus.noOrder;

  static _StepState _stateOf(RouteStopModel stop, {required bool isCurrent}) {
    if (stop.status == RouteVisitStatus.notReached) return _StepState.missed;
    if (_isVisited(stop)) return _StepState.visited;
    return isCurrent ? _StepState.current : _StepState.upcoming;
  }
}

enum _StepState { visited, missed, current, upcoming }

class _Header extends StatelessWidget {
  final int total;
  final int visited;
  final int missed;

  const _Header({
    required this.total,
    required this.visited,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = total == 0
        ? 'مفيش عملاء في خط النهاردة'
        : 'زرت $visited من $total'
            '${missed > 0 ? ' · لم يوصل $missed' : ''}';

    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedRoute01,
              color: colors.primary,
              size: 24.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تتبع خط العملاء',
                style: AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 17.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTextStyles.almaraiRegular14
                    .copyWith(color: colors.textMuted, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingStep extends StatelessWidget {
  final RouteStopModel stop;
  final int number;
  final _StepState state;
  final bool isLast;

  const _TrackingStep({
    required this.stop,
    required this.number,
    required this.state,
    required this.isLast,
  });

  bool get _handled =>
      state == _StepState.visited || state == _StepState.missed;

  void _openCustomer(BuildContext context) {
    final customer = CustomersRepository.instance.getCustomerById(stop.customerId);
    if (customer == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color accent = switch (state) {
      _StepState.current => colors.primary,
      _StepState.upcoming => colors.textMuted,
      _StepState.visited || _StepState.missed =>
        routeStatusColor(context, stop.status),
    };

    final badgeLabel = switch (state) {
      _StepState.current => 'جاري الآن',
      _StepState.upcoming => 'قادم',
      _StepState.visited || _StepState.missed => stop.status.label,
    };

    final updatedAt = stop.statusUpdatedAt;

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _openCustomer(context),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 46.w,
              child: Column(
                children: [
                  _Node(state: state, number: number, accent: accent, status: stop.status),
                  if (!isLast)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: SizedBox(
                          width: 2,
                          child: CustomPaint(
                            painter: _DashedLinePainter(
                              color: _handled
                                  ? accent.withOpacity(0.55)
                                  : colors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18.h, top: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoBold18.copyWith(
                        color: colors.text,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      stop.area.isEmpty ? 'بدون عنوان' : stop.area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.cairoMedium16
                          .copyWith(color: accent, fontSize: 11.sp),
                    ),
                  ),
                  if (_handled && updatedAt != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _formatTime(updatedAt),
                      style: AppTextStyles.almaraiRegular14
                          .copyWith(color: colors.textMuted, fontSize: 11.sp),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 03:30 م
  static String _formatTime(DateTime time) {
    final t = time.toLocal();
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute ${t.hour < 12 ? 'ص' : 'م'}';
  }
}

class _Node extends StatelessWidget {
  final _StepState state;
  final int number;
  final Color accent;
  final RouteVisitStatus status;

  const _Node({
    required this.state,
    required this.number,
    required this.accent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = state != _StepState.upcoming;

    final Widget child = switch (state) {
      _StepState.upcoming => Text(
          '$number',
          style: AppTextStyles.cairoBold18
              .copyWith(color: colors.textMuted, fontSize: 15.sp),
        ),
      _StepState.current =>
        Icon(Icons.storefront_rounded, color: Colors.white, size: 22.sp),
      _StepState.missed =>
        Icon(Icons.close_rounded, color: Colors.white, size: 24.sp),
      _StepState.visited => Icon(
          status == RouteVisitStatus.noOrder
              ? Icons.remove_rounded
              : Icons.check_rounded,
          color: Colors.white,
          size: 24.sp,
        ),
    };

    return Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accent : accent.withOpacity(0.10),
        boxShadow: state == _StepState.current
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(child: child),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0.0, size.height).toDouble()),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt_rounded, color: colors.primary, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'خلّصت كل زيارات النهاردة',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.primary, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Icon(Icons.event_available_outlined,
            color: colors.textMuted, size: 40.sp),
        SizedBox(height: 8.h),
        Text(
          'مفيش عملاء متخططين النهاردة',
          style: AppTextStyles.cairoMedium16
              .copyWith(color: colors.text, fontSize: 13.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          'حدد أيام زيارة كل عميل من خطة الأسبوع، وهيظهروا هنا تلقائيًا '
          'كل يوم الساعة 12 بالليل',
          textAlign: TextAlign.center,
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: colors.textMuted, fontSize: 11.sp),
        ),
        SizedBox(height: 12.h),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()))
              // A plan set for today's weekday generates today's visits.
              .then((_) => TodayRouteController.instance.refresh()),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('خطة الأسبوع'),
        ),
      ],
    );
  }
}
