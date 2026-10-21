import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'widgets/daily_invoices_section.dart';

class DailyInvoicesByDateScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailyInvoicesByDateScreen({super.key, this.initialDate});

  @override
  State<DailyInvoicesByDateScreen> createState() =>
      _DailyInvoicesByDateScreenState();
}

class _DailyInvoicesByDateScreenState extends State<DailyInvoicesByDateScreen> {
  late DateTime _date = _normalize(widget.initialDate ?? DateTime.now());

  DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'اختار تاريخ اليوم',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked == null || !mounted) return;
    setState(() => _date = _normalize(picked));
  }

  void _setDaysAgo(int days) {
    final now = DateTime.now();
    setState(() => _date = DateTime(now.year, now.month, now.day - days));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('فواتير يوم محدد',
            style: AppTextStyles.cairoBold18.copyWith(color: colors.text)),
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: BorderSide(color: colors.border.withOpacity(0.5)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: _pickDate,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          color: AppColors.primaryGreen, size: 22.w),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _formatDate(_date),
                          style: AppTextStyles.cairoBold18
                              .copyWith(fontSize: 16.sp, color: colors.text),
                        ),
                      ),
                      Text(
                        'غيّر التاريخ',
                        style: AppTextStyles.cairoMedium16.copyWith(
                            fontSize: 12.sp, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              children: [
                ActionChip(
                  label: const Text('النهاردة'),
                  onPressed: () => _setDaysAgo(0),
                ),
                ActionChip(
                  label: const Text('امبارح'),
                  onPressed: () => _setDaysAgo(1),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            DailyInvoicesSection(
              key: ValueKey(_date),
              date: _date,
              showDateLink: false,
            ),
          ],
        ),
      ),
    );
  }
}
