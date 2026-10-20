import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/pdf_export.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';

import '../../domain/daily_collections_pdf_builder.dart';
import '../../domain/daily_collections_repository.dart';
import 'daily_collections_by_date_screen.dart';

class DailyCollectionsSection extends StatefulWidget {
  final DateTime? date;
  final bool showDateLink;

  const DailyCollectionsSection({
    super.key,
    this.date,
    this.showDateLink = true,
  });

  @override
  State<DailyCollectionsSection> createState() =>
      _DailyCollectionsSectionState();
}

class _DailyCollectionsSectionState extends State<DailyCollectionsSection> {
  List<DailyCollectionSummary> _collections = const [];
  bool _loading = true;
  bool _sharing = false;

  DateTime get _day {
    final source = widget.date ?? DateTime.now();
    return DateTime(source.year, source.month, source.day);
  }

  DateTime get _to => DateTime(_day.year, _day.month, _day.day + 1);

  bool get _isToday {
    final now = DateTime.now();
    return _day.year == now.year &&
        _day.month == now.month &&
        _day.day == now.day;
  }

  double get _total => _collections.fold(0.0, (sum, c) => sum + c.amount);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DailyCollectionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSource = oldWidget.date ?? DateTime.now();
    final oldDay = DateTime(oldSource.year, oldSource.month, oldSource.day);
    if (oldDay != _day) {
      setState(() {
        _loading = true;
        _collections = const [];
      });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final collections = await DailyCollectionsRepository.instance
          .getDailyCollections(from: _day, to: _to);
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppError(context, e);
    }
  }

  Future<void> _share() async {
    if (_collections.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await DailyCollectionsPdfBuilder.build(_collections, _day);
      if (!mounted) return;
      await PdfExport.share(
        bytes,
        'daily-collections-${_day.year}-${_day.month}-${_day.day}.pdf',
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                child: Icon(Icons.payments_outlined,
                    color: AppColors.primaryGreen, size: 20.w),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                    _isToday
                        ? 'التحصيلات اليومية'
                        : 'تحصيلات يوم ${_formatDate(_day)}',
                    style: AppTextStyles.cairoBold18
                        .copyWith(fontSize: 16.sp, color: colors.text)),
              ),
              if (!_loading && _collections.isNotEmpty)
                TextButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined, size: 16),
                  label: const Text('مشاركة التحصيلات'),
                ),
            ],
          ),
          if (widget.showDateLink)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DailyCollectionsByDateScreen(),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('تحصيلات يوم محدد'),
              ),
            ),
          SizedBox(height: 12.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_collections.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                    _isToday
                        ? 'لسه مفيش تحصيلات النهاردة'
                        : 'مفيش تحصيلات في اليوم ده',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.textMuted)),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'إجمالي التحصيلات (${_collections.length})',
                    style: AppTextStyles.cairoMedium16
                        .copyWith(fontSize: 13.sp, color: colors.textMuted),
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.cairoBold18
                      .copyWith(fontSize: 15.sp, color: AppColors.primaryGreen),
                ),
              ],
            ),
            Divider(color: colors.border.withOpacity(0.5), height: 20.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _collections.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.border.withOpacity(0.5), height: 16.h),
              itemBuilder: (context, index) {
                final collection = _collections[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.customerName,
                            style: AppTextStyles.cairoMedium16
                                .copyWith(fontSize: 13.sp, color: colors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${collection.code}  •  ${_formatTime(collection.date)}  •  ${collection.method?.displayLabel ?? '-'}',
                            style: AppTextStyles.almaraiRegular14.copyWith(
                                fontSize: 10.sp, color: colors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${collection.amount.toStringAsFixed(0)} ج.م',
                      style: AppTextStyles.cairoBold18.copyWith(
                          fontSize: 13.sp, color: AppColors.primaryGreen),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
