import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/arabic_date_utils.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

/// A small, self-contained clock — updates every second on its own so the
/// date and time on this screen never need to be entered by hand.
class LiveDateTimeCard extends StatefulWidget {
  const LiveDateTimeCard({super.key});

  @override
  State<LiveDateTimeCard> createState() => _LiveDateTimeCardState();
}

class _LiveDateTimeCardState extends State<LiveDateTimeCard> {
  late DateTime now;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar,
                    size: 16.sp, color: AppColors.primaryGreen),
                SizedBox(width: 8.w),
                Text(
                  arabicDateLabel(now),
                  style: AppTextStyles.cairoMedium16
                      .copyWith(color: colors.text, fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 18.h, color: colors.border),
          SizedBox(width: 14.w),
          Row(
            children: [
              Icon(CupertinoIcons.time, size: 16.sp, color: AppColors.statBlue),
              SizedBox(width: 8.w),
              Text(
                time24Label(now),
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: colors.text, fontSize: 13.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
