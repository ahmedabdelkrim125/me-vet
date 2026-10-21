import 'package:flutter/material.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer_account/domain/entities/payment_method.dart';

import '../../domain/daily_collections_repository.dart';
import '../daily_collections_share_service.dart';
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
  String? _customerId;

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

  List<DailyCollectionSummary> get _visible => _customerId == null
      ? _collections
      : _collections.where((c) => c.customerId == _customerId).toList();

  List<MapEntry<String, String>> get _customers {
    final map = <String, String>{};
    for (final c in _collections) {
      map.putIfAbsent(c.customerId, () => c.customerName);
    }
    final list = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list;
  }

  String? get _selectedName {
    if (_customerId == null) return null;
    for (final entry in _customers) {
      if (entry.key == _customerId) return entry.value;
    }
    return null;
  }

  double get _total => _visible.fold(0.0, (sum, c) => sum + c.amount);

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
        _customerId = null;
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

  Future<void> _shareVisible() => DailyCollectionsShareService.askAndShare(
        context,
        _visible,
        _day,
        customerName: _selectedName,
      );

  Future<void> _shareCustomer(DailyCollectionSummary collection) {
    final items =
        _collections.where((c) => c.customerId == collection.customerId);
    return DailyCollectionsShareService.askAndShare(
      context,
      items.toList(),
      _day,
      customerName:
          collection.customerName.isEmpty ? 'عميل' : collection.customerName,
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        customers: _customers,
        selectedId: _customerId,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _customerId = picked.isEmpty ? null : picked);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _buildCustomerFilter(AppColorScheme colors) {
    final name = _selectedName;
    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: colors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: _pickCustomer,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(Icons.person_search_outlined,
                  color: AppColors.primaryGreen, size: 20.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  name ?? 'كل العملاء',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cairoMedium16
                      .copyWith(fontSize: 13.sp, color: colors.text),
                ),
              ),
              if (_customerId != null)
                InkWell(
                  onTap: () => setState(() => _customerId = null),
                  child: Icon(Icons.close, size: 18.w, color: colors.textMuted),
                )
              else
                Icon(Icons.arrow_drop_down, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

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
              if (!_loading && _visible.isNotEmpty)
                TextButton.icon(
                  onPressed: _shareVisible,
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: Text(
                    _customerId == null ? 'مشاركة التحصيلات' : 'مشاركة العميل',
                  ),
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
          if (!_loading && _collections.isNotEmpty) ...[
            _buildCustomerFilter(colors),
            SizedBox(height: 12.h),
          ],
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
                    'إجمالي التحصيلات (${_visible.length})',
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
              itemCount: _visible.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.border.withOpacity(0.5), height: 16.h),
              itemBuilder: (context, index) {
                final collection = _visible[index];
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
                          if (collection.invoiceLabel.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              'الفاتورة: ${collection.invoiceLabel}',
                              style: AppTextStyles.almaraiRegular14.copyWith(
                                fontSize: 10.sp,
                                color: collection.isEditDifference
                                    ? AppColors.primaryGreen
                                    : colors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${collection.amount.toStringAsFixed(0)} ج.م',
                      style: AppTextStyles.cairoBold18.copyWith(
                          fontSize: 13.sp, color: AppColors.primaryGreen),
                    ),
                    if (_customerId == null)
                      IconButton(
                        onPressed: () => _shareCustomer(collection),
                        tooltip: 'مشاركة تحصيلات العميل',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.share_outlined,
                            size: 18.w, color: colors.textMuted),
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

class _CustomerPickerSheet extends StatefulWidget {
  final List<MapEntry<String, String>> customers;
  final String? selectedId;

  const _CustomerPickerSheet({
    required this.customers,
    required this.selectedId,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = widget.customers
        .where((e) => e.value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.all(12.w),
          padding: EdgeInsets.all(16.w),
          constraints: BoxConstraints(maxHeight: 70.sh),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختار العميل',
                textAlign: TextAlign.center,
                style: AppTextStyles.cairoBold18
                    .copyWith(color: colors.text, fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم العميل',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              ListTile(
                dense: true,
                leading: const Icon(Icons.groups_outlined),
                title: const Text('كل العملاء'),
                selected: widget.selectedId == null,
                onTap: () => Navigator.pop(context, ''),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(entry.value.isEmpty ? 'عميل' : entry.value),
                      selected: widget.selectedId == entry.key,
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
